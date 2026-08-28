terraform {
  required_version = ">= 1.9"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0"
    }
    azuread = {
      # Needed only for the dedicated test group in test_dependencies.tf -
      # see the comment there for why a Service Principal can't be used
      # directly as a PIM eligible-assignment principal.
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
  }

  # Empty on purpose: the state file path is supplied at `terraform init`
  # time via `-backend-config="path=..."` (partial configuration), so the
  # target-branch checkout and the PR-branch checkout can point at the same
  # external state file without either owning its own local state.
  backend "local" {}
}

provider "azurerm" {
  storage_use_azuread             = true
  resource_provider_registrations = "legacy"
  features {}
}

provider "azuread" {}

module "pim_eligible_role_assignment" {
  # PR code and baseline code are two on-disk checkouts of this same repo,
  # not two resolved git refs - no pinned ?ref, no version toggle here.
  source = "../../"

  scope              = [azurerm_resource_group.live_test.id]
  custom_scope_names = ["probe"]
  principal_id       = [azuread_group.live_test.object_id]
  role_definition    = var.role_definition

  pim_eligible_role_assignment = {
    schedule = {
      expiration = {
        duration_days = 30
      }
    }
  }
}
