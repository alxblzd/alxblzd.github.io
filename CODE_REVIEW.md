# Code Review Notes: Terraform Proxmox Cloud-Init Article

## Summary
- Initial review of the new Proxmox + Terraform cloud-init guide.
- Focused on metadata consistency, security posture, and correctness of the example workflows.
- Follow-up pass added build tooling notes to keep the site shippable while iterating on content.

## Findings
1. **Missing author metadata in front matter**
   - The post omits the `author` field that other posts include, which can remove author attribution and affect layout components that expect it (e.g., post headers). Consider adding `author: "Alxblzd"` to match the rest of the site.
   - Reference: `_posts/2025-11-06-proj-terraform-proxmox-cloudinit.md` lines 1-6.

2. **API token role grants very broad privileges**
   - The sample role creation command assigns a large set of permissions (including `Sys.Modify`, `Permissions.Modify`, and many VM controls), which exceeds least-privilege requirements for typical Terraform provisioning. This could expose the cluster if the token is leaked.
   - Suggest restricting the role to VM lifecycle privileges (e.g., clone/create/start/console) on a specific pool/datastore and avoiding system-wide permission grants.
   - Reference: `_posts/2025-11-06-proj-terraform-proxmox-cloudinit.md` lines 43-48.

3. **"Adding More VMs" tfvars snippet is incomplete**
   - The instructions append a bare object to `terraform.tfvars` without wrapping it in a list or assigning it to the `vms` variable. As written, the resulting file is invalid HCL and `terraform apply` will fail to parse it.
   - Recommend showing a full example (e.g., `vms = [ { ... } ]` or appending to an existing list) so readers can apply changes without syntax errors.
   - Reference: `_posts/2025-11-06-proj-terraform-proxmox-cloudinit.md` lines 275-290.

4. **Jekyll build reliability**
   - Added an explicit Ruby version, Gemfile dependencies (`jekyll`, `webrick`), and a README with copy/paste setup instructions so contributors can install and run `bundle exec jekyll build/serve` without guessing.
   - Introduced a GitHub Actions check (`.github/workflows/jekyll-build.yml`) to run the same build in CI for consistency.
   - Added a "Quick start" section to the README with the exact clone/install/serve commands so testers can verify the site locally (light/dark mode, homepage, projects) without digging through docs.
   - Documented the rubygems.org 403 scenario with guidance to switch to an allowed mirror when corporate networks block direct gem downloads.
   - Updated the CI workflow to pin Ruby 3.2.3 so Bundler aligns with `.ruby-version` and avoids the 3.2.9 vs 3.2.3 lockfile error.
   - Adjusted the workflow to read the Ruby version directly from `.ruby-version` and added a manual trigger so reviewers can start a fresh check without new commits.
