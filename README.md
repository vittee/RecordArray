# RecordArray

Delphi Typed Pointer made easy.

## What is it?
It is just a small unit for creating an array of a certain type at runtime, forget the `GetMem()` and `FreeMem()` and `try..finally` block.

Usually when an array is needed to be used as a pointer, we must allocate a memory block representing the array by using the `GetMem()` or `alloc()` by specifing element's size times the number of elements, then call `FreeMem()` to free up the memory.

This will result in this boring code.

```pascal
var
  pWordArray: PWord;
begin
  pWordArray := GetMem(SizeOf(Word) * 10); // create 10 elements of Word
  try
    // Do something with the memory
  finally
    FreeMem(pWordArray);
  end;
end;
```

This unit helps eliminate that long code blocks into a single line.
```pascal
  pWordArray := TRecordArray<PWord>.Create(10); // create a memory block for array of 10 words.
```

Why not use built-in dynamic array?
-----------------------------------
Yes, we can use dynamic array instead of manually allocating/deallocating the memory, but Delphi's dynamic array has its own memory layout and byte alignment, which sometimes incompatible with most C API.

Features
--------
* Work with any pointer types.
* Flat memory layout, no byte alignment (packed)
* Suitable for using with Win/C API.
* Automatic reference counting (via Interface/COM), auto release memory.
* Accessing element without doing pointer math.
* Memory re-allocation, resizable array.

## How to use

### Creating
```pascal
var
  WordArray: IRecordArray<PWord>; // IRecordArray enables auto-release feature.
begin
  WordArray := TRecordArray<PWord>.Create(10); // Create an array with 10 elements of Word
  // WordArray will be automatically deallocated when the function exit or no longer used.
end;
```

> The data is stored in memory as little-endian on x86-64 CPU 

If the data is already allocated somewhere else, just put the pointer to that data and specify the length directly.
```pascal
var
  WordArray: IRecordArray<PWord>;
begin
  WordArray := TRecordArray<PWord>.Create(PointerToWords, 10); // Create an array with 10 elements of Word using a pointer.
end;
```

### Getting array's length
```pascal
  WordArray.Length
```

### Resizing
```pascal
  WordArray.Length := WordArray.Length + 5; // Expand 5 elements
  WordArray.Length := WordArray.Length - 5; // Shrink the last 5 elements
```

### Getting an element
```pascal
var
  I: Integer;
begin
  for I := 0 to WordArray.Length - 1 do
    DoSomethingWithWord(WordArray[I]^);
end;
```

### Getting element's size
```pascal
  WordArray.ElementSize
```

### Getting memory size
```pascal
  WordArray.DataSize
```

### Getting memory block
```pascal
  WordArray.Data
```

### Joining another array
```pascal
  WordArray.Append(AnotherWordArray)
```

### Using with record/struct

A record type must has its pointer type declared. 

```pascal
type
  TMyRecord = packed record
    Value1: Integer;
    Value2: Integer;
  end;
  
  PMyRecord = ^TMyRecord;
  
var
  MyRecordArray: IRecordArray<PMyRecord>;
  I: Integer;
begin
  MyRecordArray := TRecordArray<PMyRecord>.Create(100);
  for I := 0 to MyRecordArray.Length - 1 do
  begin
    MyRecordArray[I].Value1 := I * 5;
    MyRecordArray[I].Value2 := I * 10;
  end;
end;
```
