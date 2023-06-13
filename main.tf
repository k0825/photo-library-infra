module "datastore" {
  source = "./modules/datastore"

  photo_library_name = var.photo_library_name
}

module "create_thumbnail" {
  source = "./modules/create_thumbnail"

  mapping_table_name = module.datastore.mapping_table_name
  photo_library_name = var.photo_library_name
}

module "storage" {
  source = "./modules/storage"

  photo_library_name         = var.photo_library_name
  create_thumbnail_queue_arn = module.create_thumbnail.create_thumbnail_queue_arn
}
