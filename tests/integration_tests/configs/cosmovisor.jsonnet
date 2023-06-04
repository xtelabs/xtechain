local config = import 'default.jsonnet';

config {
  'xtechain_9527-1'+: {
    'app-config'+: {
      'minimum-gas-prices': '100000000000axte',
    },
    genesis+: {
      app_state+: {
        feemarket+: {
          params+: {
            base_fee:: super.base_fee,
          },
        },
      },
    },
  },
}
