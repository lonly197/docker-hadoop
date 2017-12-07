# docker-hadoop

> Hadoop(Common/HDFS/YARN/MapReduce) docker image based on alpine.

## Build

```bash
docker build --build-arg VCS_REF=`git rev-parse --short HEAD` \
--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
--rm \
-t lonly/docker-hadoop:2.9.0 .
```

## License

![License](https://img.shields.io/github/license/lonly197/docker-alpine-python.svg)

## Contact me

- Email: <lonly197@qq.com>
