### `track(_:file:function:line:)`

```swift
public func track(_ message: String, file: String = #file, function: String = #function, line: Int = #line )
```

Used for debugging messages - mostly during development. Il will probably go away at some point, but it's useful while I bang my head against edge-cases
- Parameters:
  - message: the message to print
  - file: location info - file (defaults to where it is)
  - function: location info - function (defaults to where it is)
  - line: location info - line (defaults to where it is)

#### Parameters

| Name | Description |
| ---- | ----------- |
| message | the message to print |
| file | location info - file (defaults to where it is) |
| function | location info - function (defaults to where it is) |
| line | location info - line (defaults to where it is) |