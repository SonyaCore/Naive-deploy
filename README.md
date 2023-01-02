# Naïve-deploy ![shell]

Deploy Naïveproxy on docker in the fastest time

> NaïveProxy uses Chromium's network stack to camouflage traffic with strong censorship resistance and low detectability. Reusing Chrome's stack also ensures best practices in performance and security.

## Installation

Naïve requires a domain and can't be used with CDN
For Deploying Naïveproxy you must pass your `Domain` and `Authentication name`(optional)

```bash
curl https://raw.githubusercontent.com/SonyaCore/Naive-deploy/main/naive.sh | bash -s test.doman.com
```

Setting NAME for Naïve authentication

```bash
curl https://raw.githubusercontent.com/SonyaCore/Naive-deploy/main/naive.sh | bash -s test.doman.com NAME
```

> If you don't pass the authentication name the default will be `Naive`

After that, you can use the generated link to connect with your client or use the CLIENT config file with naive client binary

ex:

```bash
 ./naive -c config.json
```

[shell]: https://img.shields.io/badge/Shellscript-green
[license]: LICENSE
