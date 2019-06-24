### Core-iOS framework

How to:

#### Install [SwiftLint](https://github.com/realm/SwiftLint)

- `> brew install swiftlint`

#### Fetch dependencies

- first of all you need to install `Carthage`

```
$ brew update
$ brew install carthage

```

- then you should run this from the root folder

```
carthage bootstrap --platform ios --no-use-binaries --cache-builds

```

```
carthage update --platform ios --no-use-binaries --cache-builds
```
