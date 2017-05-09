Same as `local` except using host volume with `./v/*` for debugging purpose.
Thus, we can see configs and data and logs for all nodes via docker host.

```shell
make start
tail -F v/9001/data/mysql/ubuntu.log
```
