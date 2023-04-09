 terraform { 
	required_providers { 
		yandex = {
			source = "yandex-cloud/yandex" //глобальный адрес источника провайдера
		}
	}
}

provider "yandex" { //название провайдера
	token = "y0_AgAAAABILCSCAATuwQAAAADeFOMS7UKvjVnQThOntRdGs_Ez3WIdBfQ"
	cloud_id = "b1gkieva61dbkorf2q2h"
	folder_id = "b1gd4d7843kr3km8urvc"
	zone = "ru-central1-b"
}

resource "yandex_compute_instance" "sykamashin" {
	name = "sykamashin"
	platform_id = "standard-v1"
	zone = "ru-central1-b"
	description = "создал ВМ через терраформ"
	
	resources { //вычеслительные ресурсы (обязательно)
		cores = 2
		memory = 2
	}
	
	boot_disk { //загрузочный диск (обязательно)
		initialize_params { //параметры нового диска
			image_id = var.image-id // образ диска для инициализации этого диска
		}
	}
	
	network_interface { // сети для подключения к экземпляру, можно указать несколько.
		subnet_id = var.syka-subnet // ID подсети, к которой нужно подключить этот интерфейс, подсеть должна существовать в тойже зоне, где будет создан этот экземпляр
		nat = true //предоставить публичны адрес, например для доступа в интерент 
	
	}
	
	metadata = { //пары "ключ-значение" метаданных, чтобы сделать их доступными из экземпляра
		ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
	}
}

resource "yandex_vpc_network" "network-syka" {
	name = "network-syka"
	description = "создал сеть через терраформ"
}

resource "yandex_vpc_subnet" "syka-subnet" {
	name = "syka-subnet"
	zone = "ru-central1-b"
	network_id = "${yandex_vpc_network.network-syka.id}"
	v4_cidr_blocks = ["10.2.0.0/16"]
	description = "Создал подсеть через терраформ"
}





resource "yandex_mdb_postgresql_cluster" "cluster-psql-1" {
  name        = "cluster-psql-1"
  environment = "PRESTABLE"
  network_id  = yandex_vpc_network.network-syka.id

  config {
    version = 12
    resources {
      resource_preset_id = "s2.micro"
      disk_type_id       = "network-hdd"
      disk_size          = 16
    }
    postgresql_config = {
      max_connections                   = 395
      enable_parallel_hash              = true
      vacuum_cleanup_index_scale_factor = 0.2
      autovacuum_vacuum_scale_factor    = 0.34
      default_transaction_isolation     = "TRANSACTION_ISOLATION_READ_COMMITTED"
      shared_preload_libraries          = "SHARED_PRELOAD_LIBRARIES_AUTO_EXPLAIN,SHARED_PRELOAD_LIBRARIES_PG_HINT_PLAN"
    }
  }

database {
    name  = "psql-1"
    owner = "PowerfullMashin"
  }
 
  user {
    name       = "PowerfullMashin"
    password   = "mycatisRaisa123"
    conn_limit = 50
    permission {
      database_name = "psql-1"
    }
    settings = {
      default_transaction_isolation = "read committed"
      log_min_duration_statement    = 5000
    }
  }

  host {
    zone      = "ru-central1-b"
    subnet_id = yandex_vpc_subnet.syka-subnet.id
  }
}





output "internal_ip_address_vm_1" {
  value = yandex_compute_instance.sykamashin.network_interface.0.ip_address
}
 
output "external_ip_address_vm_1" {
  value = yandex_compute_instance.sykamashin.network_interface.0.nat_ip_address
}
