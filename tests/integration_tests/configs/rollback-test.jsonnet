local config = import 'default.jsonnet';

config {
  'xtechain_9527-1'+: {
    validators: super.validators[0:1] + [{
      name: 'fullnode',
    }],
  },
}
