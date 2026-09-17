part of 'queue_processor.dart';

typedef AppStorageRef = Ref;
typedef MockApiRef = Ref;

@ProviderFor(appStorage)
final appStorageProvider = Provider<AppStorage>(
  appStorage,
  name: 'appStorageProvider',
);

@ProviderFor(mockApi)
final mockApiProvider = Provider<MockApiService>(
  mockApi,
  name: 'mockApiProvider',
);

@ProviderFor(QueueProcessor)
final queueProcessorProvider =
    NotifierProvider<QueueProcessor, int>(QueueProcessor.new);

abstract class _$QueueProcessor extends Notifier<int> {}
