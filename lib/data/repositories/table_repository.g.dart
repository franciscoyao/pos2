// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'table_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(tableRepository)
const tableRepositoryProvider = TableRepositoryProvider._();

final class TableRepositoryProvider
    extends
        $FunctionalProvider<TableRepository, TableRepository, TableRepository>
    with $Provider<TableRepository> {
  const TableRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tableRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tableRepositoryHash();

  @$internal
  @override
  $ProviderElement<TableRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TableRepository create(Ref ref) {
    return tableRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TableRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TableRepository>(value),
    );
  }
}

String _$tableRepositoryHash() => r'28e1bf8a3ea9c6423d61b9bd1d4e34655ebe4af0';
