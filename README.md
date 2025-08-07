# Tf Rules

The Tf rules are useful to validate, lint and format terraform code.

They can typically be used in a terraform monorepo of modules to lint, run validation tests, auto generate documentation and enforce the consistency of Tf and providers versions across all modules.

# Why "Tf" and not "Terraform"

Because now you can either use "tofu" or "terraform" binary.

## Getting Started

To import rules_tf in your project, you first need to add it to your `MODULE.bazel` file:

```python
bazel_dep(name = "rules_tf", version = "0.0.10")
# git_override(
#     module_name = "rules_tf",
#     remote      = "https://github.com/yanndegat/rules_tf",
#     commit      = "...",
# )

tf = use_extension("@rules_tf//tf:extensions.bzl", "tf_repositories", dev_dependency = True)
tf.download(
    version = "1.9.5",
    tflint_version = "0.53.0",
    tfdoc_version = "0.19.0",
    use_tofu = False,
    mirror = {
        "random" : "hashicorp/random:3.3.2",
        "null"   : "hashicorp/null:3.1.1",
    }
)

# Switch to tofu
# tf = use_extension("@rules_tf//tf:extensions.bzl", "tf_repositories")
# tf.download(
#    version = "1.6.0",
#    use_tofu = True,
#    mirror = {
#        "random" : "hashicorp/random:3.3.2",
#        "null"   : "hashicorp/null:3.1.1",
#    }
# )

use_repo(tf, "tf_toolchains")
register_toolchains(
    "@tf_toolchains//:all",
    dev_dependency = True,
)
```

### Using Tf rules

Once you've imported the rule set, you can then load the tf rules in your `BUILD` files with:

```python
load("@rules_tf//tf:def.bzl", "tf_providers_versions", "tf_module")

tf_providers_versions(
    name = "providers",
    tf_version = "1.2.3",
    providers = {
        "random" : "hashicorp/random:>=3.3",
        "null"   : "hashicorp/null:>=3.1",
    },
)

tf_module(
    name = "root-mod-a",
    providers = [
        "random",
    ],
    deps = [
        "//tf/modules/mod-a",
    ],
    providers_versions = ":providers",
    # disable_version_lint = True,  # Set to true to disable versions.tf.json validation
)
```

The `tf_module` macro automatically creates several test targets:
- `:format` - Checks if Terraform files are properly formatted
- `:lint` - Runs tflint on the module
- `:validate` - Validates the Terraform configuration (unless `skip_validation = True`)
- `:versions_check` - Ensures `versions.tf.json` matches the BUILD file (created automatically when versions.tf.json exists, unless `disable_version_lint = True`)

#### Provider Configuration Aliases

The `providers` parameter supports both string list format and dictionary format (for configuration aliases):

```python
# String list format (legacy)
tf_module(
    name = "simple-module",
    providers = [
        "random",
        "null",
    ],
    providers_versions = ":providers",
)

# Dictionary format (for provider aliases)
tf_module(
    name = "multi-provider-module",
    providers = {
        "random": {
            "configuration_aliases": ["random.primary", "random.secondary"]
        },
        "aws": {
            "configuration_aliases": ["aws.us_east_1", "aws.us_west_2"]
        }
    },
    providers_versions = ":providers",
)
```

The dictionary format allows you to specify `configuration_aliases` for providers that need multiple configurations, which is useful for multi-region deployments or when a module needs to work with multiple instances of the same provider.

#### Skipping Validation for Nested Modules

Modules that use provider configuration aliases are designed to be nested (called by other modules) and cannot be validated standalone because they don't have concrete provider configurations. For these modules, use `skip_validation = True`:

```python
# Nested module with provider aliases - cannot validate standalone
tf_module(
    name = "multi-region-module",
    providers = {
        "aws": {
            "configuration_aliases": ["aws.us_east_1", "aws.us_west_2"]
        }
    },
    providers_versions = "//tf:versions",
    skip_validation = True,  # Required for modules with configuration aliases
)

# Root module that uses the nested module - can validate
tf_module(
    name = "root-module",
    providers = ["aws"],
    deps = ["//tf/modules/multi-region-module"],
    providers_versions = "//tf:versions",
    # skip_validation = False (default) - root modules can be validated
)
```

This is necessary because Terraform cannot validate a module that declares configuration aliases without having concrete provider configurations passed to it from a parent module.

### Using prebuilt binaries

To ensure a consistent binary version across the team, you can create an alias to the prebuilt binaries:

```python
# Likewise for tofu, tfdoc, and tflint.
alias(
    name = "terraform",
    actual = "@tf_toolchains//:terraform",
)
```

And you can use `bazel run //:terraform` which uses the same version as configured in your `MODULE.bazel`.

## Using Tf Modules

1. Using custom tflint config file

```python
load("@rules_tf//tf:def.bzl", "tf_module")

filegroup(
    name = "tflint-custom-config",
    srcs = [
        "my-tflint-config.hcl",
    ],
)

tf_module(
    name = "mod-a",
    providers = [
        "random",
    ],
    ...
    tflint_config = ":tflint-custom-config"

)
```

1. Generating and validating versions.tf.json files

Terraform linter by default requires that all providers used by a module
are versioned. It is possible to generate a versions.tf.json file by running
a dedicated target:

```python
load("@rules_tf//tf:def.bzl", "tf_providers_versions", "tf_module")

tf_providers_versions(
    name = "providers",
    tf_version = "1.2.3",
    providers = {
        "random" : "hashicorp/random:3.3.2",
        "null"   : "hashicorp/null:3.1.1",
    },
)

tf_module(
    name = "root-mod-a",
    providers = [
        "random",
    ],
    deps = [
        "//tf/modules/mod-a",
    ],

    providers_versions = ":providers",
)
```

``` bash
bazel run //path/to/root-mod-a:gen-tf-versions
```

or generate all files of a workspace:

``` bash
bazel cquery 'kind(tf_gen_versions, //...)' --output files | xargs -n1 bash
```

**Version Validation**: If your module has a `versions.tf.json` file, `tf_module` automatically creates a `versions_check` test that ensures it stays in sync with your BUILD file. If the test fails:

```bash
# The error message will show you exactly what to run:
bazel run //path/to/module:gen-tf-versions
```

To disable version validation for a specific module:

```python
tf_module(
    name = "my-module",
    providers = ["random"],
    disable_version_lint = True,  # Disables versions.tf.json validation
    ...
)
```

Note: Modules without a `versions.tf.json` file won't have version validation enabled automatically.

1. Generating terraform doc files

It is possible to generate a README.md file by running
a dedicated target for terraform modules:

```python
load("@rules_tf//tf:def.bzl", "tf_gen_doc")

tf_gen_doc(
    name = "tfgendoc",
    modules = ["//{}/{}".format(package_name(), m) for m in subpackages(include = ["**/*.tf"])],
)
```

and run the following command to generate docs for all sub packages.

``` bash
bazel run //path/to:tfgendoc
```

It is also possible to customize terraform docs config:

```python
load("@rules_tf//tf:def.bzl", "tf_gen_doc")

filegroup(
    name = "tfdoc-config",
    srcs = [
        "my-tfdoc-config.yaml",
    ],
)

tf_gen_doc(
    name   = "custom-tfgendoc",
    modules = ["//{}/{}".format(package_name(), m) for m in subpackages(include = ["**/*.tf"])],
    config = ":tfdoc-config",
)
```

1. Formatting terraform files

It is possible to format terraform files by running a dedicated target:

```python
load("@rules_tf//tf:def.bzl", "tf_format")


tf_format(
    name = "tffmt",
    modules = ["//{}/{}".format(package_name(), m) for m in subpackages(include = ["**/*.tf"])],
)
```

and run the following command to generate docs for all sub packages.

``` bash
bazel run //path/to:tffmt
```
