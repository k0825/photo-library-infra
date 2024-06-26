from PIL import Image
import hashlib
import boto3
import os
import logging
import re
import json
import urllib
from pillow_heif import register_heif_opener

register_heif_opener()
logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3 = boto3.client("s3")
dynamodb = boto3.client("dynamodb")


# S3からオリジナル画像を取得
def get_original_image(bucket, original_path):
    response = s3.get_object(Bucket=bucket, Key=original_path)
    image = Image.open(response["Body"])
    return image


def convert_png_to_jpeg(image):
    if image.mode == "PNG":
        image = image.convert("RGB")
    return image


# サムネを作ってS3にアップロード
def create_thumbnail(image, bucket, uid):
    thumbnail_dir = "thumbnail/"

    # サムネイル用のディレクトリがなければ作成
    is_dir_exists = s3.list_objects(Bucket=bucket, Prefix=thumbnail_dir)
    if not "Contents" in is_dir_exists:
        s3.put_object(Bucket=bucket, Key=thumbnail_dir)

    tmp_path = os.path.join("/tmp/", uid)
    thumbnail_path = os.path.join(thumbnail_dir, uid)
    image.save(tmp_path, "JPEG", quality=50, optimize=True)
    s3.upload_file(tmp_path, bucket, thumbnail_path)
    os.remove(tmp_path)

    return thumbnail_path


# 合致しないファイルを別ディレクトリに移動
def move_to_other_object(bucket, original_path):
    other_dir = "other/"
    filename = os.path.basename(original_path)
    other_path = os.path.join(other_dir, filename)

    # other用のディレクトリがなければ作成
    is_dir_exists = s3.list_objects(Bucket=bucket, Prefix=other_dir)
    if not "Contents" in is_dir_exists:
        s3.put_object(Bucket=bucket, Key=other_dir)

    # ファイルを移動
    s3.copy_object(
        Bucket=bucket,
        CopySource={"Bucket": bucket, "Key": original_path},
        Key=other_path,
    )
    s3.delete_object(Bucket=bucket, Key=original_path)


# 画像サイズを特定する関数
def get_image_size(image):
    width, height = image.size
    return width, height


def lambda_handler(event, context):
    pattern = ".\.(jpg|jpeg|png|gif|heic)$"
    for sqs_record in event["Records"]:
        sqs_body = json.loads(sqs_record["body"])

        # S3のイベントからバケット名とオリジナル画像のパスを取得
        for record in sqs_body["Records"]:
            logger.info(f"{len(event)}個のS3イベントを受け取りました")
            bucket = record["s3"]["bucket"]["name"]
            original_path = record["s3"]["object"]["key"]
            decode_original_path = urllib.parse.unquote_plus(original_path)

            logger.info(f"INFO-0001 ファイルパス: {decode_original_path}")

            if not re.search(pattern, decode_original_path, re.IGNORECASE):
                try:
                    move_to_other_object(bucket, decode_original_path)
                except Exception as e:
                    logger.error(f"ERROR-0001 ファイルの移動に失敗しました\n{e}")
                    return

                logger.info(
                    "INFO-0002 この拡張子は対象外のため、ファイルを移動しました"
                )
                continue

            # オリジナル画像を取得
            try:
                image = get_original_image(bucket, decode_original_path)
            except Exception as e:
                logger.error(f"ERROR-0002 オリジナル画像の取得に失敗しました\n{e}")
                return

            try:
                image = convert_png_to_jpeg(image)
            except Exception as e:
                logger.error(f"ERROR-0003 PNG画像の変換に失敗しました\n{e}")
                return

            # サムネイル画像を作成
            try:
                uid = hashlib.sha256(decode_original_path.encode()).hexdigest()
                thumbnail_path = create_thumbnail(image, bucket, uid)
            except Exception as e:
                logger.error(f"ERROR-0004 サムネイル画像の作成に失敗しました\n{e}")
                return

            try:
                width, height = get_image_size(image)
            except Exception as e:
                logger.error(f"ERROR-0005 画像サイズの取得に失敗しました\n{e}")
                return

            # DynamoDBに登録
            try:
                table_name = os.environ["MAPPING_TABLE_NAME"]
                item = {
                    "id": {"S": uid},
                    "original_path": {"S": decode_original_path},
                    "thumbnail_path": {"S": thumbnail_path},
                    "width": {"N": str(width)},
                    "height": {"N": str(height)},
                }
                dynamodb.put_item(TableName=table_name, Item=item)
            except Exception as e:
                logger.error(f"ERROR-0005 DynamoDBへの登録に失敗しました\n{e}")
                return
