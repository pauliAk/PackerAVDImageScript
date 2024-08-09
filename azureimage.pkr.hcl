packer {
  required_plugins {
    azure = {
      #version = "~> 2"
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/azure"
    }
  }
} 

variable "client_id" {
  type    = string
   default = env("ARM_CLIENT_ID")
}

variable "client_secret" {
  type    = string
  default = env("ARM_CLIENT_SECRET")
}

variable "subscription_id" {
  type    = string
    default = env("ARM_SUBSCRIPTION_ID")
}

variable "tenant_id" {
  type    = string
 default = env("ARM_TENANT_ID")
}

variable "resource_group_name" {
  type    = string
  default = env("RESOURCE_GROUP_NAME")
}


variable "gallery_image_name" {
  type    = string
  default = env("GALLERY_IMAGE_NAME")
}


variable "winrm_password" {
  type =string
  default = env("WINRM_PASSWORD")
  
}

variable "storageAccountKey" {
  type = string
  default = env("STORAGE_ACCOUNT_KEY")
  
}
variable "location" {
  type    = string
  default = "West Europe"
}

variable "gallery_name" {
  type    = string
  default = "acgAk"
}

variable "gallery_image_version" {
  type    = string
  default = "1.0.1"
}

variable "gallery_image_version_updated" {
  type    = string
  default = "1.0.3"
}

variable "storage_account_name" {
  type    = string
  default = "fslogixstorage14"
}

variable "container_name" {
  type    = string
  default = "testinstall"
}


variable "blob_name" {
  type    = string
  default = "setup.exe"
}


variable "script_to_run" {
  type    = string
  default = "Hero.msi"
}

variable "replication_regions" {
  type =list(string)
  default = [ "west europe" ]
 
}

variable "managed_image_nameACG" {
  type = string
  default = "acgImageDef2"
}


/* variable "script_to_run" {
  type    = string
  default = "installfile.ps1"
}
 */


/* variable "application_name" {
  type    = string
  default = "Microsoft Edge"
}
 */


source "azure-arm" "example" {

communicator = "winrm"
  client_id                = var.client_id
  client_secret            = var.client_secret
  subscription_id          = var.subscription_id
  tenant_id                = var.tenant_id
  managed_image_name       = "myManagedImage16"
  managed_image_resource_group_name = var.resource_group_name
  location                 = var.location
  vm_size                  = "Standard_DS2_v2"
  os_type                  = "Windows"
  winrm_username      = "kun"
  winrm_password      = var.winrm_password
  winrm_use_ssl       = true
  winrm_insecure      = true
  winrm_timeout       = "90m"

  
  shared_image_gallery {
    subscription = var.subscription_id
    resource_group = var.resource_group_name
    gallery_name = var.gallery_name
    image_name = var.gallery_image_name
    image_version = var.gallery_image_version

}

  shared_image_gallery_destination {
    gallery_name        = var.gallery_name
    # image_name          = var.managed_image_nameACG
    image_name          = var.gallery_image_name
    image_version       = var.gallery_image_version_updated # new version
    replication_regions = var.replication_regions
    resource_group      = var.resource_group_name
  }

}

build {

  sources = [
    "source.azure-arm.example"
  ]

  
   provisioner "powershell" {
    inline = [

      #"Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force",
      "Set-ExecutionPolicy Unrestricted -Scope Process -Force",
      "Set-ExecutionPolicy Unrestricted -Scope CurrentUser -Force",
      "Set-ExecutionPolicy -ExecutionPolicy unrestricted -Scope LocalMachine -Force",
      "Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false",
      "Install-Module -Name Az -Repository PSGallery -Force -AllowClobber -Confirm:$false",

      "$context = New-AzStorageContext -StorageAccountName ${var.storage_account_name} -StorageAccountKey ${var.storageAccountKey}",

# Download the blob
    "Get-AzStorageBlobContent -Container ${var.container_name} -Blob ${var.blob_name} -Destination C:\\Windows\\Temp -Context $context",
    "Get-AzStorageBlobContent -Container ${var.container_name} -Blob ${var.script_to_run} -Destination C:\\Windows\\Temp -Context $context"

    ]
  }
    provisioner "powershell" {
    inline = [

  # Define the path to the installer file
      "$installerPath = 'C:\\Windows\\temp\\setup.exe'",
      "Start-Process -FilePath $installerPath -ArgumentList '/quiet' -Wait -NoNewWindow"
      #"Start-Process -FilePath $installerPath -ArgumentList '/S' -Wait -NoNewWindow"

    ]
  }

   provisioner "powershell" {
    inline = [
  
  "Add-WindowsFeature Web-Server", "while ((Get-Service RdAgent).Status -ne 'Running') { Start-Sleep -s 5 }", "while ((Get-Service WindowsAzureGuestAgent).Status -ne 'Running') { Start-Sleep -s 5 }", "& $env:SystemRoot\\System32\\Sysprep\\Sysprep.exe /oobe /generalize /quiet /quit", "while($true) { $imageState = Get-ItemProperty HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Setup\\State | Select ImageState; if($imageState.ImageState -ne 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') { Write-Output $imageState.ImageState; Start-Sleep -s 10  } else { break } }"
  
  ]
  } 

   post-processor "manifest" {
    output = "manifest.json"
  } 
/*  
post-processor "shared-image-gallery" {

    resource_group = var.resource_group
    gallery_name   = var.gallery_name
    image_name     = var.gallery_image_name
    image_version  = var.gallery_image_version_updated
}

 */

}