local default = import 'default.jsonnet';

default {
  'xtechain_9527-1'+: {
    config+: {
      consensus+: {
        timeout_commit: '5s',
      },
    },
  },
}
