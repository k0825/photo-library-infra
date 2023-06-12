from PIL import Image
import hashlib
import boto3
import os
import logging


logger = logging.getLogger()
s3 = boto3.client("s3")
dynamodb = boto3.client("dynamodb")


# S3からオリジナル画像を取得
def get_original_image(bucket, original_path):
    response = s3.get_object(Bucket=bucket, Key=original_path)
    image = Image.open(response["Body"])
    return image


# サムネを作ってS3にアップロード
def create_thumbnail(image, bucket, thumbnail_path):
    tmp_path = os.path.join("/tmp/", thumbnail_path)
    image.save(tmp_path, "JPEG", quality=50, optimize=True)
    s3.upload_file(tmp_path, bucket, thumbnail_path)
    os.remove(tmp_path)


def lambda_handler(event, context):
    thumbnail_dir = "/thumbnail/"

    # S3のイベントからバケット名とオリジナル画像のパスを取得
    for record in event["Records"]:
        bucket = record["s3"]["bucket"]["name"]
        original_path = record["s3"]["object"]["key"]

        # オリジナル画像を取得
        try:
            image = get_original_image(bucket, original_path)
        except Exception as e:
            logger.error("オリジナル画像の取得に失敗しました")
            logger.error(e)
            return

        uid = hashlib.sha256(original_path.encode()).hexdigest()
        thumbnail_path = os.path.join(thumbnail_dir, uid)

        # サムネイル画像を作成
        try:
            is_dir_exists = s3.list_objects(Bucket=bucket, Prefix=thumbnail_path)
            if not "Contents" in is_dir_exists:
                s3.put_object(Bucket=bucket, Key=thumbnail_dir)
            create_thumbnail(image, bucket, thumbnail_path)
        except Exception as e:
            logger.error("サムネイル画像の作成に失敗しました")
            logger.error(e)
            return


        # DynamoDBに登録
        try:
            table_name = os.environ["MAPPING_TABLE_NAME"]
            item = {
                "id": {"S": uid},
                "original_path": {"S": original_path},
                "thumbnail_path": {"S": thumbnail_path},
            }
            dynamodb.put_item(TableName=table_name, Item=item)
        except:
            logger.error("DynamoDBへの登録に失敗しました")
            logger.error(e)
            return
