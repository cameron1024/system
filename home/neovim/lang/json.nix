{
  plugins.lsp.servers.yamlls.enable = true; 
  plugins.lsp.servers.jsonls.enable = true; 
  plugins.schemastore.enable = true;
  plugins.schemastore.json.enable = true;
  plugins.schemastore.yaml.enable = true;

  lsp.servers.jsonls.settings.json.schemaStore.url = "";
  lsp.servers.jsonls.settings.json.schemas.__raw = ''
    require "schemastore".json.schemas()
  '';

  lsp.servers.yamlls.settings.yaml.schemaStore.enable = false;
  lsp.servers.yamlls.settings.yaml.schemaStore.url = "";
  lsp.servers.yamlls.settings.yaml.schemas.__raw = ''
    require "schemastore".yaml.schemas()
  '';
}
