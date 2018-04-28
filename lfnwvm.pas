unit lfnwVM;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  PByteArray = ^ByteArray;
  ByteArray = Array of Byte;

  PVMState = ^VMState;

  VMOpFunc = procedure(state : PVMState); (* Procedures might be a little faster *)

  VMState = record
    SM : ByteArray; (* Stack Memory *)
    PM : ByteArray; (* Program Memory *)
    HM : ByteArray; (* Heap Memory *)
    RM : Array[0..255] of Byte; (* Register Memory *)

    SP  : LongInt; (* Stack Pointer *)
    FP  : LongInt; (* Frame Pointer *)
    PC  : LongInt; (* Program Counter *)
    CMP : LongInt; (* Compare Result Register *)

    (* Handlers for all OpCodes in our VM *)
    OpCodeHandlers : Array[0..255] of VMOpFunc;
  end;



function VM_NewState(StackSize : Cardinal; HeapSize : Cardinal; CodeFile : AnsiString) : PVMState;
procedure VM_FreeState(state : PVMState);

procedure VM_Run(state : PVMState);


procedure VM_RegisterOpHandler(state : PVMState; code : Byte; func : VMOpFunc);

implementation

(* Private Op Handlers *)
(*
  Naming convention for handlers
    I - LongInteger (Little Endian)
    B - Byte
    C - Char* (C String)
    R - Register
    H - Heap Address (Little Endian)
    A - Program Memory Address (Little Endian)
    S - Stack Operation
    O - Output

    Modifiers
    i - indirection
    l - literal
    x - array, multiple of type

*)




function VM_NewState(StackSize : Cardinal; HeapSize : Cardinal; CodeFile : AnsiString) : PVMState;
var state : PVMState;
    f : file;
    buf : Byte = 0;
    i : Integer;
    codeLength : Int64;
begin
  Result := nil;
  New(state);

  if FileExists(CodeFile) then
  begin
    (* Open and read all file bytes into ProgramMemory *)
    AssignFile(f, CodeFile);
    Reset(f, 1);
    codeLength := FileSize(f);
    SetLength(state^.PM, codeLength);
    i := 0;
    while not EOF(f) do
    begin
      BlockRead(f, buf, 1);
      state^.PM[i] := buf;
      Inc(i);
    end;

    CloseFile(f);
  end
  else
  begin
    (* Unable to open binary file *)
    WriteLn('Unable to locate file: ', CodeFile);
    Dispose(state);
    Exit();
  end;

  SetLength(state^.HM, HeapSize);
  SetLength(state^.SM, StackSize);
  FillByte(state^.RM, 256, 0);

  (* Initialize Registers *)
  state^.PC := 0;
  state^.SP := 0;
  state^.FP := -1;
  state^.CMP := 0;

  
  Result := state;
end;

procedure VM_FreeState(state : PVMState);
begin
  if not Assigned(state) then
     Exit();

  SetLength(state^.SM, 0);
  SetLength(state^.HM, 0);
  SetLength(state^.PM, 0);

  Dispose(state);
end;

procedure VM_Run(state : PVMState);
var IsEnd : Boolean = False;
    CurOpCode : Byte;
begin

  (* TODO: Check that the state is ready *)

  (* Start looping over bytes calling OpCode handlers *)
  while not IsEnd do
  begin
    CurOpCode := state^.PM[state^.PC];
    //WriteLn('OpCode: ' + IntToStr(CurOpCode));
    state^.OpCodeHandlers[CurOpCode](state);

    if state^.PC = Length(state^.PM) then
       IsEnd := True;
  end;

end;


procedure VM_RegisterOpHandler(state : PVMState; code : Byte; func : VMOpFunc);
begin
  state^.OpCodeHandlers[code] := func;
end;

end.

