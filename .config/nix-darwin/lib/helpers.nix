{ lib }: {
  # Helper to create a directory structure
  mkDirStructure = paths: lib.genAttrs paths (path: { });

  # Helper to conditionally include modules
  optionalModule = condition: module: if condition then [ module ] else [ ];

  # Helper to merge multiple attribute sets
  mergeConfigs = configs: lib.foldr lib.recursiveUpdate { } configs;
}
