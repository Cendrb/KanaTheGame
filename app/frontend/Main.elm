port module Main exposing (..)

import Json.Decode as Decode
import Json.Encode as Encode
import Json.Decode.Pipeline as DPipeline

import Browser
import Dict exposing (Dict)
import Css
import Css.Transitions
import Html.Styled exposing (..)
import Html.Styled.Attributes as Attributes
import Html.Styled.Events as Events
import Html
import Svg.Styled
import Svg.Styled.Attributes
import Svg.Styled.Events

-- MODEL

type alias Model =
  {
    state : State,
    signups : Dict Int Signup,
    role : Role,
    errorMessage : String,
    board : Maybe Board
  }

type State
  = Loading
  | Playing
  | Waiting
  | Finished

type Role
  = Waiter -- he's literally waiting for a port message saying the real role
  | Player Int -- player id
  | Spectator

type alias Board =
  {
    x : Int,
    y : Int,
    stones : Dict Int Stone,
    shapes : List Shape,
    selectedStoneId : Maybe Int
  }

type alias Stone =
  {
    id : Int,
    x : Int,
    y : Int,
    playerId : Int
  }

type alias Shape =
  {
    id : Int,
    playerId : Int,
    name : String,
    points : Int,
    traded : Bool,
    stones : List Stone
  }

type alias Signup =
  {
    userName : String,
    playerId : Int,
    spentPoints : Int,
    color : Color
  }

type alias Color =
  {
    r : Int,
    g : Int,
    b : Int
  }

type alias BoardParameters =
  {
    unit : Int,
    offset : Int
  }

-- INIT

init : (Model, Cmd Message)
init =
  (Model
    Loading
    Dict.empty
    Waiter
    ""
    Nothing
  , Cmd.none)

-- VIEW

stateToString s =
  case s of
    Loading -> "loading"
    Playing -> "playing"
    Waiting -> "waiting"
    Finished -> "finished"

renderRole role =
  case role of
    Waiter -> "waiting for server"
    Player id -> "playing with ID " ++ String.fromInt id
    Spectator -> "spectating"

renderColor : Color -> String
renderColor color =
  "rgb(" ++ String.fromInt color.r ++ "," ++  String.fromInt color.g ++ "," ++  String.fromInt color.b ++ ")"

toCssColor : Color -> Css.Color
toCssColor color =
  Css.rgb color.r color.g color.b

createCoordinateTuples : Int -> Int -> List (Int, Int)
createCoordinateTuples x y =
  List.range 0 x
    |> List.concatMap (
      \xOff -> (List.range 0 y) -- add y variants for each x
        |> List.map (\yOff -> (xOff, yOff))
    )

averageColors : Color -> Color -> Color
averageColors color1 color2 =
  Color
    ((color1.r + color2.r) // 2)
    ((color1.g + color2.g) // 2)
    ((color1.b + color2.b) // 2)

renderGridElements : Int -> Int -> BoardParameters -> List (Svg.Styled.Svg Message)
renderGridElements x y params =
  (createCoordinateTuples x y |> List.map (
    \coords -> Svg.Styled.path 
    [
      Svg.Styled.Attributes.d "m6.296296,0l38.407408,0c0.881481,3.022222 3.274074,5.288889 6.296296,6.17037l0,38.407408c-3.022222,0.881481 -5.414815,3.274074 -6.296296,6.296296l-38.407408,0c-0.881481,-3.022222 -3.274074,-5.414815 -6.296296,-6.296296l0,-38.407408c3.022222,-0.881481 5.414815,-3.148148 6.296296,-6.17037z",
      Svg.Styled.Attributes.transform (
        "translate("
        ++ (String.fromInt (Tuple.first coords * params.unit + params.offset))
        ++ ","
        ++ (String.fromInt (Tuple.second coords * params.unit + params.offset))
        ++ ") scale(0.86 0.86)"
      ),
      Svg.Styled.Events.onClick (FieldClicked coords)
    ] []
  ))
  ++ (createCoordinateTuples x y |> List.map (
    \coords -> Svg.Styled.circle
    [
      Svg.Styled.Attributes.r "5",
      Svg.Styled.Attributes.cx <| String.fromInt (Tuple.first coords * params.unit + params.offset - 3),
      Svg.Styled.Attributes.cy <| String.fromInt (Tuple.second coords * params.unit + params.offset - 3)
    ] []
  ))


getGradientIdentifier : Int -> Bool -> String
getGradientIdentifier playerId isSelected =
  "player" ++ String.fromInt playerId ++ "_" ++ if isSelected then "selected" else "regular"

isStoneSelected : Stone -> Maybe Int -> Bool
isStoneSelected stone selectedStoneId =
  case selectedStoneId of
    Just id ->
      stone.id == id
    Nothing ->
      False

renderStones : (List Stone) -> Maybe Int -> BoardParameters -> List (Svg.Styled.Svg Message)
renderStones stones selectedStoneId params =
  let
    offset = 22
    radius = 20
  in
    stones |> List.map (
      \stone ->
        Svg.Styled.circle
        [
          Svg.Styled.Attributes.r <| String.fromInt radius,
          Svg.Styled.Attributes.transform <| (
            "translate("
            ++ String.fromInt (stone.x * params.unit + offset + params.offset)
            ++ ","
            ++ String.fromInt (stone.y * params.unit + offset + params.offset)
            ++ ")"
          ),
          Svg.Styled.Attributes.fill <| "url(#" ++ (getGradientIdentifier stone.playerId (isStoneSelected stone selectedStoneId))++ ")",
          Svg.Styled.Attributes.css [
            Css.Transitions.transition [
              Css.Transitions.transform3 1000 0 Css.Transitions.easeInOut
            ]
          ],
          Svg.Styled.Events.onClick (StoneClicked stone)
        ] []
    )

renderColorTransitions : (Dict Int Signup) -> List (Svg.Styled.Svg Message)
renderColorTransitions signups =
  List.concat [
    signups |> Dict.values |> List.map (
      \signup ->
        Svg.Styled.radialGradient [
          Svg.Styled.Attributes.id (getGradientIdentifier signup.playerId False),
          Svg.Styled.Attributes.cx "66%",
          Svg.Styled.Attributes.cy "66%",
          Svg.Styled.Attributes.fx "66%",
          Svg.Styled.Attributes.fy "66%"
        ] [
          Svg.Styled.stop [
            Svg.Styled.Attributes.offset "0",
            Svg.Styled.Attributes.stopColor <| renderColor <| (averageColors signup.color (Color 300 300 300))
          ] [],
          Svg.Styled.stop [
            Svg.Styled.Attributes.offset "0.270588",
            Svg.Styled.Attributes.stopColor <| renderColor <| (averageColors signup.color (Color 200 200 200))
          ] [],
          Svg.Styled.stop [
            Svg.Styled.Attributes.offset "1",
            Svg.Styled.Attributes.stopColor <| renderColor <| signup.color
          ] []
        ]
    ),
    signups |> Dict.values |> List.map (
      \signup ->
        Svg.Styled.radialGradient [
          Svg.Styled.Attributes.id (getGradientIdentifier signup.playerId True),
          Svg.Styled.Attributes.cx "33%",
          Svg.Styled.Attributes.cy "33%",
          Svg.Styled.Attributes.fx "33%",
          Svg.Styled.Attributes.fy "33%"
        ] [
          Svg.Styled.stop [
            Svg.Styled.Attributes.offset "0",
            Svg.Styled.Attributes.stopColor <| renderColor <| (averageColors signup.color (Color 300 300 300))
          ] [],
          Svg.Styled.stop [
            Svg.Styled.Attributes.offset "0.270588",
            Svg.Styled.Attributes.stopColor <| renderColor <| (averageColors signup.color (Color 200 200 200))
          ] [],
          Svg.Styled.stop [
            Svg.Styled.Attributes.offset "1",
            Svg.Styled.Attributes.stopColor <| renderColor <| signup.color
          ] []
        ]
    )
  ]

renderBoard : Board -> (Dict Int Signup) -> Html Message
renderBoard board signups =
  let
      params = BoardParameters
        50
        4
  in
    Svg.Styled.svg [ Svg.Styled.Attributes.viewBox (
      "0 0 "
      ++ String.fromFloat (toFloat (board.x * params.unit + params.offset) - 2.5)
      ++ " "
      ++ String.fromFloat (toFloat (board.y * params.unit + params.offset) - 2.5)) 
    ] 
    (
      (renderGridElements board.x board.y params)
      ++ (renderStones (board.stones |> Dict.values) board.selectedStoneId params)
      ++ [
        Svg.Styled.defs [] (renderColorTransitions signups)
      ]
    )

view : Model -> Html Message
view model = 
  
  -- The inline style is being used for example purposes in order to keep this example simple and
  -- avoid loading additional resources. Use a proper stylesheet when building your own app.
  div[] [
    h1 []
     [stateToString model.state |> text],
    ul [] (Dict.values model.signups |> List.map (\n -> li [ Attributes.css [ Css.color <| toCssColor <| n.color ]  ] [ text n.userName ]) ),
    p [] [ text model.errorMessage ],
    p [] [ text <| "you are " ++ renderRole model.role ],
    case model.board of
      Just board ->
        renderBoard board model.signups
      Nothing ->
        div [] [ text "No board" ]
  ]

-- MESSAGE

type Message
  = StateReceived (Result String State)
  | SignupsReceived (Result Decode.Error (List Signup))
  | RoleReceived (Result String Role)
  | BoardReceived (Result Decode.Error Board)
  | StoneClicked Stone
  | FieldClicked (Int, Int)

-- PORTS
port statePort : (String -> msg) -> Sub msg
port signupsPort : (Decode.Value -> msg) -> Sub msg
port rolePort : (Decode.Value -> msg) -> Sub msg
port boardPort : (Decode.Value -> msg) -> Sub msg

port playPort : Encode.Value -> Cmd msg

-- UPDATE

setSelectedStoneId : Maybe Int -> Maybe Board -> Maybe Board
setSelectedStoneId id maybeBoard =
  case maybeBoard of
    Just board ->
      {board | selectedStoneId = id} |> Just
    Nothing ->
      maybeBoard

getSelectedStoneId : Maybe Board -> Maybe Int
getSelectedStoneId maybeBoard =
  case maybeBoard of
    Just board ->
      board.selectedStoneId
    Nothing ->
      Nothing 

getStonesDict : Maybe Board -> Dict Int Stone
getStonesDict maybeBoard =
  case maybeBoard of
    Just board ->
      board.stones
    Nothing ->
      Dict.empty

createPlayCommand : (Int, Int) -> (Int, Int) -> Cmd msg
createPlayCommand from to =
  Encode.object [
    ("from", Encode.object [
      ("x", Encode.int <| Tuple.first from),
      ("y", Encode.int <| Tuple.second from)
    ]),
    ("to", Encode.object [
      ("x", Encode.int <| Tuple.first to),
      ("y", Encode.int <| Tuple.second to)
    ])
  ] |> playPort

updateToPlayAt : Model -> Int -> (Int, Int) -> (Model, Cmd msg)
updateToPlayAt model selectedStoneId coords =
  let
    maybeSelectedStone = Dict.get selectedStoneId (getStonesDict model.board)
  in
    case maybeSelectedStone of
      Just prevSelectedStone ->
        (
          {model | board = model.board |> setSelectedStoneId (Nothing)},
          createPlayCommand (prevSelectedStone.x, prevSelectedStone.y) coords
        )
      Nothing ->
        ({model | errorMessage = "Selected stone disappeared"}, Cmd.none)

update : Message -> Model -> (Model, Cmd Message)
update message model =
  case message of
    StateReceived result ->
      case result of
        Ok value ->
          ({model | state = value}, Cmd.none)
        Err errorMessage ->
          ({model | errorMessage = errorMessage}, Cmd.none)
    SignupsReceived result ->
      case result of
        Ok data ->
          let 
            signupDictionary = List.map (\n -> (n.playerId, n)) data |> Dict.fromList
          in
            ({model | signups = signupDictionary}, Cmd.none)
        Err error ->
          ({model | errorMessage = Decode.errorToString error}, Cmd.none)
    RoleReceived result ->
      case result of
        Ok value ->
          ({model | role = value}, Cmd.none)
        Err errorMessage ->
          ({model | errorMessage = errorMessage}, Cmd.none)
    BoardReceived result ->
      case result of
        Ok data ->
          ({model | board = Just data}, Cmd.none)
        Err error ->
          ({model | errorMessage = Decode.errorToString error}, Cmd.none)
    StoneClicked stone ->
      case getSelectedStoneId model.board of
        Just selectedStoneId ->
          updateToPlayAt model selectedStoneId (stone.x, stone.y)
        Nothing ->
          ({model | board = model.board |> setSelectedStoneId (Just stone.id)}, Cmd.none)
    FieldClicked coords ->
      case getSelectedStoneId model.board of
        Just selectedStoneId ->
          updateToPlayAt model selectedStoneId coords
        Nothing ->
          (model, Cmd.none)

-- SUBSCRIPTIONS

parseStateString : String -> Result String State
parseStateString string =
  case string of
    "loading" ->
      Ok Loading
    "playing" ->
      Ok Playing
    "waiting" ->
      Ok Waiting
    "finished" ->
      Ok Finished
    _ ->
      Err <| string ++ " is not a valid match state"

decodeRole : Decode.Value -> Result String Role
decodeRole data =
  case Decode.decodeValue (Decode.field "role" Decode.string) data of
    Ok stringRole ->
      case stringRole of
        "play" ->
          case Decode.decodeValue (Decode.field "player_id" Decode.int) data of
            Ok playerId ->
              Ok (Player playerId)
            Err error ->
              Err <| "failed to parse player ID"
        "spectate" ->
          Ok Spectator
        _ ->
          Err <| stringRole ++ " is not a valid role"
    Err error ->
      Err <| Decode.errorToString error


colorDecoder : Decode.Decoder Color
colorDecoder =
  Decode.succeed Color
    |> DPipeline.required "r" Decode.int
    |> DPipeline.required "g" Decode.int
    |> DPipeline.required "b" Decode.int

signupDecoder : Decode.Decoder Signup
signupDecoder =
  Decode.succeed Signup
    |> DPipeline.required "user_name" Decode.string
    |> DPipeline.required "player_id" Decode.int
    |> DPipeline.required "spent_points" Decode.int
    |> DPipeline.required "color" colorDecoder

decodeSignups : Decode.Value -> Result Decode.Error (List Signup)
decodeSignups data =
  Decode.decodeValue
    (Decode.list signupDecoder)
    data

stoneDecoder : Decode.Decoder Stone
stoneDecoder =
  Decode.succeed Stone 
    |> DPipeline.required "id" Decode.int
    |> DPipeline.required "x" Decode.int
    |> DPipeline.required "y" Decode.int
    |> DPipeline.required "player_id" Decode.int


shapeDecoder : Decode.Decoder Shape
shapeDecoder =
  Decode.succeed Shape 
    |> DPipeline.required "id" Decode.int
    |> DPipeline.required "player_id" Decode.int
    |> DPipeline.required "name" Decode.string
    |> DPipeline.required "points" Decode.int
    |> DPipeline.required "traded" Decode.bool
    |> DPipeline.requiredAt [ "board_data", "stones" ] (Decode.list stoneDecoder)

boardDecoder : Decode.Decoder Board
boardDecoder =
  Decode.succeed Board
    |> DPipeline.requiredAt [ "board_data", "width" ] Decode.int
    |> DPipeline.requiredAt [ "board_data", "height" ] Decode.int
    |> DPipeline.requiredAt [ "board_data", "stones" ] (Decode.list stoneDecoder |> Decode.andThen (\list -> List.map (\n -> (n.id, n)) list |> Dict.fromList |> Decode.succeed))
    |> DPipeline.required "fulfilled_shapes" (Decode.list shapeDecoder)
    |> DPipeline.hardcoded Nothing

decodeBoard : Decode.Value -> Result Decode.Error Board
decodeBoard data =
  Decode.decodeValue
    boardDecoder
    data

subscriptions : Model -> Sub Message
subscriptions model =
  Sub.batch [
    statePort (parseStateString >> StateReceived), -- function composure
    signupsPort (decodeSignups >> SignupsReceived), -- decoding a json
    rolePort (decodeRole >> RoleReceived),
    boardPort (decodeBoard >> BoardReceived)
  ]

-- MAIN

main : Program (Maybe {}) Model Message
main =
  Browser.element
    {
      init = always init,
      view = view >> Html.Styled.toUnstyled,
      update = update,
      subscriptions = subscriptions
    }
