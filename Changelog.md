# ActiveModelAttributes Changelog

## master

## 1.1.0

Changes:
  - [BUGFIX] Pass `options` argument to `ActiveModel::Type.lookup` in attribute writers @jughead

## 1.0.0

Update notes:

  - Breaking change: the attribute's setter now calls #cast method on type instead of #deserialize. If you have defined any custom type, just rename the method from #deserialize to #cast

Changes:
  - [ENHANCEMENT] Use #cast method from types instead of #deserialize by @Azdaroth

## 0.1.0

Update notes:

  - None

Changes:
  - [FEATURE] Basic implementation by @Azdaroth
