{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/CODER/K8042LIB-TP)
  @abstract(Target: Turbo Pascal 7)
}

Unit K8042LIB;

INTERFACE

Const
 K8042_STATUS=$64;    (* (Ecriture) *)
 K8042_COMMAND=$64;   (* (Ecriture) *)
 K8042_DATA=$60;      (* (Lecture/êcriture) *)

  (* Bits d'Çtat *)
 K8042_STATUS_OUTPUT_FULL=$01;
 K8042_STATUS_INPUT_FULL=$02;
 K8042_STATUS_SYSTEM=$04;
 K8042_STATUS_DATA_WRITE=$08;
 K8042_STATUS_INHIBIT=$10;
 K8042_STATUS_XMIT_TIMEOUT=$20;
 K8042_STATUS_MOUSE_OUTPUT_FULL=$20;
 K8042_STATUS_RECV_TIMEOUT=$40;
 K8042_STATUS_PARITY_ERR=$80;

 K8042_IRQ=1;
 K8042_MOUSE_IRQ=12;

 K8042_F_AUX=$01;

Procedure k8042_Disable_Aux;
Procedure k8042_Disable_Keyboard;
Procedure k8042_Drain_Buffer;
Procedure k8042_Enable_Aux;
Procedure k8042_Enable_Keyboard;
Function  k8042_Is_Mouse_Output_Ready:Boolean;
Function  k8042_Is_Output_Ready:Boolean;
Function  k8042_Output_Was_Aux:Boolean;
Function  k8042_Probe:Boolean;
Function  k8042_Read_Command_Byte:Integer;
Function  k8042_Read_Output:Byte;
Function  k8042_Read_Output_Wait:Integer;
Function  k8042_Wait_For_Input_Buffer:Boolean;
Function  k8042_Wait_For_Output:Byte;
Function  k8042_Write_Aux(C:Byte):Boolean;
Function  k8042_Write_Command(C:Byte):Boolean;
Function  k8042_Write_Command_Byte(C:Byte):Boolean;
Function  k8042_Write_Data(C:Byte):Boolean;


IMPLEMENTATION

Var
 k8042_Flags,k8042_Last_Status:Byte;

Function k8042_Is_Output_Ready:Boolean;Begin
 k8042_Last_Status:=Port[K8042_STATUS];
 k8042_Is_Output_Ready:=(k8042_Last_Status and K8042_STATUS_OUTPUT_FULL)=
                         K8042_STATUS_OUTPUT_FULL;
End;

Function k8042_Is_Mouse_Output_Ready:Boolean;Begin
 k8042_Last_Status:=Port[K8042_STATUS];
 k8042_Is_Mouse_Output_Ready:=(k8042_Last_Status and
        (K8042_STATUS_OUTPUT_FULL or K8042_STATUS_MOUSE_OUTPUT_FULL)) =
        (K8042_STATUS_OUTPUT_FULL or K8042_STATUS_MOUSE_OUTPUT_FULL);
End;

Function k8042_Output_Was_Aux:Boolean;Begin
 k8042_Output_Was_Aux:=((k8042_Flags and K8042_F_AUX) <> 0) and
                       ((k8042_Last_Status and K8042_STATUS_MOUSE_OUTPUT_FULL)<>0);
End;

Function k8042_Read_Output:Byte;Begin
 k8042_Read_Output:=Port[K8042_DATA];
End;

Function k8042_Wait_For_Output:Byte;
Var
 Patience:Word;
 C:Byte;
Begin
 Patience:=$FFFF;
 Repeat
  C:=Port[K8042_STATUS];
  Dec(Patience);
 Until Not(((C and K8042_STATUS_OUTPUT_FULL)=0)and(Patience<>0));
 k8042_Last_Status:=C;
 k8042_Wait_For_Output:=(C and K8042_STATUS_OUTPUT_FULL);
End;

Function k8042_Read_Output_Wait:Integer;Begin
 If(k8042_Wait_For_Output or
    k8042_Wait_For_Output or
    k8042_Wait_For_Output<>0)Then
  k8042_Read_Output_Wait:=k8042_Read_Output
 Else
  k8042_Read_Output_Wait:=-1;
End;

Function k8042_Wait_For_Input_Buffer:Boolean;
Var
 Patience:Word;
 C:Byte;
Begin
 Patience:=$FFFF;
 Repeat
  C:=Port[K8042_STATUS];
  Dec(Patience);
 Until Not(((C and K8042_STATUS_INPUT_FULL<>0)and(Patience<>0)));
 k8042_Last_Status:=C;
 k8042_Wait_For_Input_Buffer:=(C and K8042_STATUS_INPUT_FULL)=0;
End;

Function k8042_Probe:Boolean;Begin
 If(Port[K8042_STATUS]=$FF)Then k8042_Probe:=False
                           Else k8042_Probe:=True;
End;

Procedure k8042_Drain_Buffer;
Var
 C,X:Byte;
Begin
 Repeat
  X:=Port[K8042_DATA];
  C:=Port[K8042_STATUS];
 Until Not((C and (K8042_STATUS_INPUT_FULL or K8042_STATUS_OUTPUT_FULL))<>0);
 k8042_Last_Status:=C;
End;

Function k8042_Write_Command(C:Byte):Boolean;
Var
 R:Boolean;
Begin
 R:=k8042_Wait_For_Input_Buffer;
 If(R)Then Port[K8042_COMMAND]:=C;
 k8042_Write_Command:=R;
End;

Function k8042_Write_Data(C:Byte):Boolean;
Var
 R:Boolean;
Begin
 R:=k8042_Wait_For_Input_Buffer;
 If(R)Then Port[K8042_DATA]:=C;
 k8042_Write_Data:=R;
End;

Function k8042_Read_Command_Byte:Integer;Begin
 If(k8042_Write_Command($20))Then k8042_Read_Command_Byte:=k8042_Read_Output_Wait
                             Else k8042_Read_Command_Byte:=-1;
End;

Function k8042_Write_Command_Byte(C:Byte):Boolean;Begin
 If(k8042_Write_Command($60)and k8042_Write_Data(c))Then k8042_Write_Command_Byte:=True
                                                    Else k8042_Write_Command_Byte:=False;
End;

Procedure k8042_Disable_Keyboard;Begin
 k8042_Write_Command($AD);
End;

Procedure k8042_Enable_Keyboard;Begin
 k8042_Write_Command($AE);
End;

Procedure k8042_Disable_Aux;Begin
 k8042_Write_Command($A7);
End;

Procedure k8042_Enable_Aux;Begin
 k8042_Write_Command($A8);
End;

Function k8042_Write_Aux(C:Byte):Boolean;Begin
 k8042_Write_Aux:=k8042_Write_Command($D4) and k8042_Write_Data(C);
End;

BEGIN
 k8042_Flags:=0;
 k8042_Last_Status:=0;
END.