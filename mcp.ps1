# User-scope MCP servers. Secrets are NEVER written here: servers read them from env vars
# that you set outside the repo (setx, SecretManagement, Key Vault). ASCII-only.
# Plugins (context7, playwright, figma) are managed via settings.json / /plugin instead.

# Example: Microsoft Learn docs (no auth)
# claude mcp add --scope user --transport http microsoft-learn https://learn.microsoft.com/api/mcp

# Example: Azure DevOps MCP (org name is not a secret; auth comes from az login)
# claude mcp add --scope user ado -- npx -y @azure-devops/mcp <your-org>

# Example: read-only SQL via a wrapper that fetches the connection string itself
# (see knowledge base, MCP + MSSQL): keep such servers in the project .mcp.json instead.

"Edit this file and uncomment the servers you need, then run it once per machine."
