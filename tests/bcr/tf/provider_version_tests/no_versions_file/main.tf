# Module without versions.tf.json
resource "null_resource" "test" {
  triggers = {
    test = "value"
  }
}