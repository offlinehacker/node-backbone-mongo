{ fetchbower, buildEnv }:
buildEnv { name = "bower-env"; ignoreCollisions = true; paths = [
  (fetchbower "underscore" "1.6.0" "~1.6.0" "1vdci1rkcc5d8m1vdx3zf1a7bgw19jzslzpha3rf7l7syv5sa5w2")
  (fetchbower "jquery" "2.1.0" "~2.1.0" "0k1hqbk1fh0qza7k751s16vi32jns1bncygnynfv3h5br8arx5nn")
  (fetchbower "backbone" "1.1.2" "~1.1.2" "0djzcnqxjfppr32hjd0ji9pzdfz7qf4286zxshkyw6gr3vlmx17c")
]; }
