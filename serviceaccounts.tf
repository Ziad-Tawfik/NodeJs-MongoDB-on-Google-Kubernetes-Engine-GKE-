# Create 2 Service accounts
resource "google_service_account" "service_account" {
  count        = length(var.sa_acc_id)
  account_id   = var.sa_acc_id[count.index]
  display_name = var.sa_acc_desc[count.index]
  depends_on   = [time_sleep.wait_project_init]
}

# Grant Artifact Registry Writer & Kubernetes Admin Roles 
# to Management SA
resource "google_project_iam_member" "man_sa_roles" {
  count   = length(var.management_roles)
  project = var.project
  role    = var.management_roles[count.index]
  member  = "serviceAccount:${google_service_account.service_account[0].email}"
}

resource "google_project_iam_member" "workload_sa_roles" {
  count   = length(var.workload_roles)
  project = var.project
  role    = var.workload_roles[count.index]
  member  = "serviceAccount:${google_service_account.service_account[1].email}"
}