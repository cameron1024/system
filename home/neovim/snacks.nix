{ pkgs, ... }: {
  home.packages = with pkgs; [imagemagick];
  programs.nixvim.plugins.snacks = {
    enable = true;
    lazyLoad = {
      enable = true;
      settings.filetypes = ["markdown" "typst"];
      settings.keys = [
        {
          desc = "Files";
          __unkeyed-1 = "<leader>n";
          __unkeyed-2.__raw = /* lua */ ''
            function() Snacks.picker.files() end
          '';
        }
        {
          desc = "Grep";
          __unkeyed-1 = "<leader>f";
          __unkeyed-2.__raw = /* lua */ ''
            function() Snacks.picker.grep() end
          '';
        }
      ];
    };


    settings = {
      picker.layout = "ivy" ;
      image.enable = true;
    };
  };
}
