

#  Layers_Router - Library 

Framework for creating Screen Route Layers for FMX (in Test) and VCL.

The Layers_Router Library aims to facilitate the call of screens being TForm or TFrame and Layouts embedded in FMX applications, and Panels in VCL applications, reducing screen coupling, giving more dynamism and practicality in building rich interfaces in Delphi.

## ⚙️&nbsp; INSTALLATION 

You can implement the Framework in two ways.

#### Implementation by the [**Boss**](https://github.com/HashLoad/boss) (Dependency manager to the Delphi)
```javascript
>  boss install https://github.com/Kyuorhan/Layers_Router/releases 
```
If you don't have Boss installed or don't know how to use the manager, follow the methods in link below.

* Get in the [**GitHub**](https://github.com/HashLoad/boss)

#### Manual Implementation, download the Library and register in the  your Delphi the Library-Path, select path of the Library's SRC folder

 * Download [**Setup**](https://github.com/Kyuorhan/Layers_Router/releases)

## ⚡️&nbsp; Quickstart

To use the Layers_Router - Library create your routes, you must start up the USES the Layers_Router.

```delphi
>  uses Layers_Router;
```

#### Remark:
Inside the SRC folder contains the Layers_Router.inc, this file has the compilation directive for Firemonkey, with this directive commented out the Framework will have VCL support, and when you uncomment you will have FMX support.

## Creation the a screen for routes

For the route system to work, you must create a new VCL or FMX form and Implement the ILayers_RouterComponent Interface, it belongs to a Layers_Router.Interfaces unit, so it must be included in your Units.

All the construction of screens based on routes use TPanel or TLayout to embed the screen calls, this way is necessary that your new screen have a TPanel or TLayout and all other components must be included within this Panel or Layout.

## 🖥️&nbsp; Getting start implementation in VCL

The implementation of the Interface ILayers_RouterComponent requires the declaration of three methods ( RendTheForm, RendTheFrame e UnRender ), the RendTheForm or RendTheFrame is always called when a route trigger a screen and UnRender always when it exits the exhibition.

```java
>  RendTheForm: is only called when your Class is really a Form of the class TForm;
```
```java
>  RendTheFrame: is only called when your Class is really a Frames of the class TFrame;
```  

#### &nbsp;Exemple in VCL :scroll:

Create a new Form in your application, include on a Panel aligned to the AlClient, implement the methods as below.

Keep in mind this screen will be rendered for your Main screen.

```delphi
unit Template;

interface

uses
  System.SysUtils, 
  System.Types, 
  System.UITypes, 
  System.Classes, 
  System.Variants,

  // Layers_Router Library
  Layers_Router.Interfaces;

type
  TTemplate = class(TForm, ILayers_RouterComponent)
  private
    { Private declarations }
  public
    { Public declarations }
    function RendTheForm : TForm;
    function RendTheFrame : TFrame;
    procedure UnRender;
  end;

var
  Template : TTemplate;

{$R *.dfm}

{ TTemplate }

function TTemplate.RendTheForm: TForm;
begin
  Result := Self; // only returns Result.Self, if your screen be a TForm;
end;

function TTemplate.RendTheFrame: TFrame;
begin
  Result := Self; // only returns Result.Self, if your screen be a TFrame;
end;

procedure TTemplate.UnRender;
begin

end;

end.
```

Understand that the method RendTheForm or RendTheFrame which us define the Result as Self, is necessary because he needs a TForm or TFrame return, will be embed always that a route is triggered. 

## 🖥️&nbsp; Getting start implementation in FMX

The implementation of the Interface ILayers_RouterComponent requires the declaration of two methods (Render and UnRender), Render is always called when a route trigger a screen, and the UnRender always when it exits the exhibition.

Below the Code of a simple screen implementing the interface ILayers_RouterComponent and ready to be utilized.

#### &nbsp;Exemple in FMX: :scroll:

Create a new Form in your application, include on a Layout AlClient aligned and implement the methods as below.

Keep in mind this screen will be rendered for your Main screen.

```delphi
unit Template;

interface

uses
  System.SysUtils, 
  System.Types, 
  System.UITypes, 
  System.Classes, 
  System.Variants,
  FMX.Types, 
  FMX.Controls, 
  FMX.Forms, 
  FMX.Graphics, 
  FMX.Dialogs,
  Layers_Router.Interfaces;

type
  TTemplate = class(TForm, ILayers_RouterComponent)
    Layout1: TLayout;
  private
    { Private declarations }
  public
    { Public declarations }
    function Render : TFMXObject;
    procedure UnRender;
  end;

var
  Template : TTemplate;

implementation

{$R *.fmx}

{ TTemplate }

function TTemplate.Render: TFMXObject;
begin
  Result := Layout1;
end;

procedure TTemplate.UnRender;
begin

end;

end.
```

Take note that in the method Render we define as Result the Layout1, it is necessary because this layout will be embed always that a route is triggered.

## REGISTERING THE ROUTE FOR THE SCREEN

Now that we already have a screen to be registered, let's go to the procedure which will make your screen ready to be triggered at any time.

To register a route is necessary assert a USES  Layers_Router it provides access to all library methods and in many cases will be the only coupling needed for your Views.

```delphi
>  uses Layers_Router;
```    

Once declared just call the method below to declare the Form or Frame that we created earlier as a route.

```java
>  TLayers_Router.Switch.Router('Inicio', TStandards_Principal);
```    

To make our application easier, we can create a new separate Unit in this case as a class, just to register the routes or call a method in onCreate from your main form, for this follow the method below.

```delphi
unit TThrows_Router;

interface

type
  TThrows_Router = class
    private
    public
      constructor Create;
      destructor Destroy; override;
      class function New : TThrows_Router;
  end;

var
  Throws_Router : TThrows_Router;

implementation

{ TThrows_Router }

uses
  Layers_Router,
  TTemplate,
  TTest1,


constructor TThrows_Router.Create;
begin
  TLayers_Router
    .Switch
      .Router('Template', TTemplate)
{
      .Router('Test', TTest)
      .Router('Test', TTest)
}
      .Router('Test1', TTest1);
end;

destructor TThrows_Router.Destroy;
begin

  inherited;
end;

class function New : TThrows_Router;
begin
  Result := Self.Create;
end;

initialization
  Throws_Router := TThrows_Router.New;

finalization
  Throws_Router.Free;
  
end.
```

Note that we have a Throws_Router variable that is a global variable and we have an initialization and termination method, will be responsible for creating routes or destroying them when necessary.

Ready we already have a Route Class created, this way our Form or Frame, no longer need to know the USES of our screens, just activate our route system and ask for the route name eg: "Template" which was instantiated by the TThrows_Router Class that will be displayed in the application's Panel_Main or Layout_Main.

## Defining the Main Render

We already have a screen and a route for us to utilize, now we need to only define where the route will renderize the Panel or Layout, i.e, what will be your Object that will receive the embedded screens.

For that in the main form of your application, declare a USES Layers_Router and at the onCreate make the following call.

Notice that in the last step we have made use in the event onCreate from the main form to register the routes.

```java  
>  TLayers_Router.Switch.Router('Inicio', TPrimeiraTela);
```
```java 
>  TLayers_Router.Render<TPrimeiraTela>.SetElement(Layout1, Layout1);
```
else.

```java
>  TLayers_Router.Render<TPrimeiraTela>.SetElement(Layout1, Layout1);
```

The method Render is responsible for defining in the library which will be the Layouts Main or Panel_Main and Index of the application.

The Render receive as generic the name of Class from your starting screen, it will be rendered when the application open inside the Layout or Panel that was informed as first parameter of SetElement

The first parameter  of SetElement is defining in which Layout or Panel the library will render a new screen whenever a route Link is called.

The second parameter of SetElement is defining what is the Layout Index from application, so when an IndexLink is called it will be renderized in this Layout, later the IndexLink will be better explained.

Done, now when opening the application we will have the Layout from Form TPrimeiraTela already being rendered inside the Panel or Layout from the main form of your application.

## Triggering the new screen via the route using the link

Now let's suppose that there are more than one screen called TSegundaTela and if you want it to go back at TPrimeiraTela from a button, from there lets use the system of Links of Layers_Router to call a TSegundaTela without the need to give USES on it.

Just call the method below in the Button Click Event.

```delphi
procedure TPrimeiraTela.Button1Click(Sender: TObject);
begin
  TLayers_Router.Link.&Throw('Tela2');
end;
```
Understand that TPrimeiraTela don't recognize the TSegundaTela, because the USES from the same was only given to Standards_Principal where it is necessary for the Register from routes. 

If you wish to keep it more organized, is suggested to create a stand-alone unit only for the registry of the routes with a Class Procedure and make a call from this method at onCreate from the Standards_Principal.

This way we end a lot of cross-referencing and coupling between screens.

## RENDER´s

```java
>  TLayers_Router.Render<T>.SetElement(MainContainer, IndexContainer);
```

Render is the first action to be done for work with the Layers_Router, because on it you will set up the Container Main and Index.

MainContainer = The Container where the forms will be embed;

IndexContainer = The main Container from the application (useful when you have more then one type of Layout or Panel in the application);

## SWITCH´s

```java
>  TLayers_Router.Switch.Router(APath : String; ARouter : TPersistentClass);
```
In the SWITCH it registers your routes, passing the name of the route and the object that is opened when this route is triggered.

```java
>  TLayers_Router.Switch.Router(APath : String; ARouter : TPersistentClass; ASidebarKey : String = 'SBIndex'; IsVisible : Boolean = True);
```

In SWITCH there are a few parameters more that already have values as Default

aSidebarKey: This parameter allows you to separate routes by category for creating dynamic menus with the SideBar class, it will be better explained below.

isVisible: Allows you to hide the route in the dynamic generation from the menus with the SideBar.

## :link:&nbsp; LINK´s

There are 3 ways to call the LINK:

```java
>  TLayers_Router.Link.&Throw (APatch : String);
```
```java 
>  TLayers_Router.Link.&Throw (APatch : String; AComponent : TPanel/TFMXObject);
```
```java     
>  TLayers_Router.Link.&Throw (APatch : String; APropersys : TPropersys; AKey : String = '');
```

The LINK are the actions to trigger the routes that you registered in the SWITCH.

```java
>  TLayers_Router.Link.&Throw (APatch : String);
```

Passing only the Path of the routes, this way the form associated at the route will embed inside the MainContainer that you defined on the render

```java
>  TLayers_Router.Link.&Throw (APatch : String; AComponent : TFMXObject);
```

Passing the Path and the Component, it will embed the registered form in the path inside the component that you are passing in the parameter.

```java
>  TLayers_Router.Link.&Throw (APatch : String; APropersys : TPropersys; AKey : String = '');
```

You can trigger a route passing Propersys, that are values that your form will recieve at the moment of render, it will be explained in detail bellow, but it is useful for example when you wish send a ID for a screen to perform a query in the database to be loaded with the data.

## PROPERSYS - ATTRIBUTES

```java
>  TLayers_Router.Link.&Throw (APatch : String; APropersys : TPropersys; AKey : String = '');
```

The library Layers_Router incorporates the Event_Bus from the Delphi to realize actions for Pub and Sub, with that you can register your forms to receive events at the call from the links. 

To receive an APropersys, you need to add USES  Layers_Router.Propersys to your form and implement the following method with the attribute [Subscribe_Attributes]

```delphi
[Subscribe_Attributes]
procedure Propersys(AValue: TPropersys);
```

and implement it

```delphi
procedure TPageCadastros.Propersys(AValue: TPropersys);
begin
    if AValue.Key = 'telacadastro' then
        Label1.Text := AValue.PropString;
  AValue.Free;
end;
```
Thus, your form is ready to, for example, receive a past string in the link call.

To call a link passing a Propersys, you use the following code:

```java
>  TLayers_Router.Link.&Throw('Cadastros', TPropersys.Create.ProprsString('Olá').Key('telacadastro'));
```
Passing in the Link the TPropersys object with the ProprsString and a KEY so that the screen that will receive it can be sure that that Propersys was sent to it.


## SIDEBAR´s

With the registered routes it can create an automatic menu of the registered routes in a dynamic way, it is enough to register a new route and it will be available for all your menus.

```java
TLayers_Router
    .SideBar
      .MainContainer(Layout5)
      .LinkContainer(Layout4)
      .FontSize(15)
      .FontColor(4294967295)
      .ItemHeigth(60)
    .RenderToListBox;
```

In the above example, we are generating a menu in the format of listbox inside of Layout5 and all the links clicked in this menu will be rendered on the Layout, if it can't pass the LinkContainer the same shall be rendered at MainContainer informed at Render from Layers_Router.

You can also create menus based on categorized routes, it is enough at the route record to inform which category the route belongs

```java
>  TLayers_Router.Switch.Router('Clientes', TPagePrincipal, 'cadastros');
```
```java 
>  TLayers_Router.Switch.Router('Fornecedores', TSubCadastros, 'cadastros');
```
```java 
>  TLayers_Router.Switch.Router('Produtos', TSubCadastros, 'cadastros');
```

Thus, we created 3 routes in the registration category, to generate a menu with only these links is enough to inform this in the construction of SideBar.

```java
TLayers_Router
    .SideBar
      .Name('cadastros')
      .MainContainer(Layout5)
      .LinkContainer(Layout4)
      .FontSize(15)
      .FontColor(4294967295)
      .ItemHeigth(60)
    .RenderToListBox;
```
