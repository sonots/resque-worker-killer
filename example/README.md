Start a resque worker

```
$ QUEUE=* TERM_CHILD=1 bundle exec rake resque:work
```

Enqueue

```
$ bundle exec rake test
```

See logs of resque:work
