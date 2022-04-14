unit ububbles;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls, DateUtils;

type

  { TForm1 }

  TBubble = class
     public
       bx,by:real;  //координати
       br:real;     //радіус
       bclr:TColor; //колір

       kx,ky:real; //коефіцієнти напрямку
       spd:real;   //швидкість

       procedure Move;
       constructor Create(x,y,r:real;clr:TColor);
  end;


  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Image1: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Panel1: TPanel;
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure runsim;
    procedure SpawnBubble;
    procedure updatetime;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure render;
    procedure FormResize(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;
  renderfield: TBitmap;
  ts1:TDateTime;
  deltatime:real;
  fw,fh:integer;
  bubbles: array of TBubble;
  insim:boolean=false;
  fpssmp:array of real;

implementation

{$R *.lfm}

{ TForm1 }


function getrandominrange(minr,maxr:integer):integer;
var min,max,b:integer;
begin
  min:=minr;
  max:=maxr;
  if min>max then
  begin
    b:=min;
    min:=max;
    max:=b;
  end;

  b:=max-min;

  result:=min+random(b)+random(2);

end;

procedure TForm1.SpawnBubble;
var tr:integer;
begin
  tr:=getrandominrange(5,25);
  setlength(bubbles,length(bubbles)+1);
  bubbles[high(bubbles)]:=TBubble.Create(
    getrandominrange(tr,fw-tr),
    getrandominrange(tr,fh-tr),
    tr,
    RGBToColor(Random(256),Random(256),Random(256))
  );
  Label1.Caption:='Bubbles on scene: '+inttostr(length(bubbles));
end;

procedure TForm1.updatetime;
var ctv:TDateTime;
  i:integer;
  sum:real;
begin
  ctv:=now;
  deltatime:=millisecondsbetween(ctv,ts1)/1000;
  ts1:=ctv;

  if (deltatime<>0) then
  begin
  if (Length(fpssmp)<100) then
  begin
    SetLength(fpssmp,length(fpssmp)+1);
    fpssmp[high(fpssmp)]:=1/deltatime;
  end;
  if length(fpssmp)>=100 then
  begin
    for i:=0 to 98 do fpssmp[i]:=fpssmp[i+1];
    fpssmp[high(fpssmp)]:=1/deltatime;
  end;
  end;
  if Length(fpssmp)>0 then
  begin
    sum:=0;
    for i:=0 to (Length(fpssmp)) do
    sum:=sum+fpssmp[i];
  end;
  Label2.Caption:='FPS: '+floattostr(sum/length(fpssmp));
end;

procedure tform1.runsim;
var i:integer;
begin
  while (insim) do
  begin
    updatetime;
    if Length(bubbles)>0 then
    for i:=0 to Length(bubbles)-1 do
    begin
      bubbles[i].Move;
    end;
    render;
    Application.ProcessMessages;
  end;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  SpawnBubble;
end;

procedure TForm1.Button3Click(Sender: TObject);
var i:integer;
begin
  for i:=0 to 99 do
  begin
    SpawnBubble;
  end;
end;

procedure Tform1.render;
var w,h,i:integer;
begin
  //створимо об'єкт та визначимо його розмір
  renderfield:=TBitmap.Create();
  renderfield.Width:=Image1.Width;
  renderfield.Height:=Image1.Height;
  w:=Image1.Width;
  h:=Image1.Height;

  //малюємо
  renderfield.Canvas.Pen.Color:=clBlack;
  renderfield.Canvas.Brush.Color:=clWhite;

  renderfield.Canvas.Rectangle(0,0,w,h);

  with renderfield.Canvas do
  begin
    if Length(bubbles)>0 then
    for i:=0 to Length(bubbles)-1 do
    begin
      Brush.Color:=bubbles[i].bclr;
      Ellipse(
        round(bubbles[i].bx-bubbles[i].br),
        round(bubbles[i].by-bubbles[i].br),
        round(bubbles[i].bx+bubbles[i].br),
        round(bubbles[i].by+bubbles[i].br) );
    end;
  end;

  //вивід зображення на видимий контекст
  Image1.Canvas.CopyRect(
    Rect(0,0,w,h),       //куди ми копіюємо
    renderfield.Canvas,  //що саме ми копіюємо
    Rect(0,0,w,h)        //яку частину ми копіюємо
  );

  //очистимо пам'ять після завршення відмальовки
  renderfield.Free;
  {FreeAndNil(renderfield);}
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  if not insim then
  begin
    insim:=true;
    runsim;
  end
  else
    insim:=false;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  fw:=Image1.Width;
  fh:=Image1.Height;
  ts1:=Now;
  randomize;
end;

procedure TForm1.FormResize(Sender: TObject);
begin
  Image1.Picture.Bitmap.Width:=Image1.Width;
  Image1.Picture.Bitmap.Height:=Image1.Height;
  fw:=Image1.Width;
  fh:=Image1.Height;
end;


constructor TBubble.Create(x,y,r:real;clr:TColor);
begin
  Self.bx:=x;
  Self.by:=y;
  Self.br:=r;
  Self.bclr:=clr;

  Self.spd:=getrandominrange(80,340);
  Self.kx:=getrandominrange(-1,1);
  Self.ky:=getrandominrange(-1,1);
  if (kx=0) then self.kx:=1;
  if (ky=0) then self.ky:=1;
end;


procedure TBubble.Move;
begin
  self.bx:=bx+kx*spd*deltatime;
  self.by:=by+ky*spd*deltatime;
  if ((bx-br)<0) then
  begin
    self.bx:=br;
    self.kx:=kx*(-1);
  end;
  if ((by-br)<0) then
  begin
    self.by:=br;
    self.ky:=ky*(-1);
  end;

  if ((bx+br)>fw) then
  begin
    self.bx:=fw-br;
    self.kx:=kx*(-1);
  end;
  if ((by+br)>fh) then
  begin
    self.by:=fh-br;
    self.ky:=ky*(-1);
  end;
end;

end.

