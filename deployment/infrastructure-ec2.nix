let
  # Insert your AWS access key here
  accessKey = "AKIAIKPKKLF6Q5UM2KBQ";
in {
  # Mapping of our 'server' machine
  server = { resources, ... }:
    { deployment.targetEnv = "ec2";
      # We'll be deploying a micro instance to Virginia
      deployment.ec2.region = "us-east-1";
      deployment.ec2.instanceType = "m1.small";
      deployment.ec2.accessKeyId = accessKey;
      # We'll let NixOps generate a keypair automatically
      deployment.ec2.keyPair = resources.ec2KeyPairs.helloapp-kp.name;
      # This should be the security group we just created
      deployment.ec2.securityGroups = [ "default" ];
    };

  # Here we create a keypair in the same region as our deployment
  resources.ec2KeyPairs.helloapp-kp = {
    region = "us-east-1";
    accessKeyId = accessKey;
  };
}
