port module Main exposing (..)

import Json.Decode as Decode
import Json.Encode as Encode
import Json.Decode.Pipeline as DPipeline

import Browser
import Dict exposing (Dict)
import Css
import Debug
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
    board : Board
  }

type State
  = Playing
  | Waiting
  | Finished

type Role
  = Player Int -- player id
  | Spectator

type alias Board =
  {
    x : Int,
    y : Int,
    stones : Dict Int Stone,
    shapes : List Shape,
    selectedStoneId : Maybe Int,
    currentPlayerId : Maybe Int
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

type alias Flags =
  {
    state : String,
    signups : Decode.Value,
    role : Decode.Value,
    board : Decode.Value
  }

-- INIT

init : Flags -> (Model, Cmd Message)
init flags =
  (Model
      (case parseStateString flags.state of
        Ok state -> state
        Err error -> error |> Debug.todo)
      (case Decode.decodeValue signupsDecoder flags.signups of
        Ok signups -> signups |> toDictionaryWithKey .playerId
        Err error -> error |> Decode.errorToString |> Debug.todo)
      (case decodeRole flags.role of
        Ok role -> role
        Err error -> error |> Debug.todo)
      ""
      (case Decode.decodeValue boardDecoder flags.board of
        Ok board -> board
        Err error -> error |> Decode.errorToString |> Debug.todo)
    , Cmd.none)
      

-- VIEW

stateToString s =
  case s of
    Playing -> "playing"
    Waiting -> "waiting"
    Finished -> "finished"

renderRole role =
  case role of
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
      Svg.Styled.Events.onClick (FieldClicked coords),
      Svg.Styled.Attributes.css [
        Css.fill <| Css.rgb 255 255 255
      ]
    ] []
  ))
  ++ (createCoordinateTuples x y |> List.map (
    \coords -> Svg.Styled.circle
    [
      Svg.Styled.Attributes.r "5",
      Svg.Styled.Attributes.cx <| String.fromInt (Tuple.first coords * params.unit + params.offset - 3),
      Svg.Styled.Attributes.cy <| String.fromInt (Tuple.second coords * params.unit + params.offset - 3),
      Svg.Styled.Attributes.css [
        Css.fill <| Css.rgb 255 255 255
      ]
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
      ++ String.fromFloat (toFloat (board.y * params.unit + params.offset) - 2.5)),
      Svg.Styled.Attributes.css [
        Css.property "flex" "0 0 auto"
      ]
    ] 
    (
      (renderGridElements board.x board.y params)
      ++ (renderStones (board.stones |> Dict.values) board.selectedStoneId params)
      ++ [
        Svg.Styled.defs [] (renderColorTransitions signups)
      ]
    )

defaultBackground : Color
defaultBackground = Color 181 183 186

getCurrentSignup : Model -> Maybe Signup
getCurrentSignup model =
  case model.role of
    Player currentPlayerId ->
      model.signups |> Dict.get currentPlayerId
    Spectator ->
      model.signups |> Dict.values |> List.reverse |> List.head

getOtherSignup : Model -> Maybe Signup
getOtherSignup model =
  case model.role of
    Player currentPlayerId ->
      model.signups |> Dict.remove currentPlayerId |> Dict.values |> List.head
    Spectator ->
      model.signups |> Dict.values |> List.head

executeIfPresent : (a -> b) -> b -> Maybe a -> b
executeIfPresent func d source =
  case source of
    Just just -> func just
    Nothing -> d

view : Model -> Html Message
view model = 
  let
    currentSignup = getCurrentSignup model
    otherSignup = getOtherSignup model
    playerStyle = \current -> Attributes.css [
      Css.property "text-align" "center",
      Css.property "margin" "0.5em",
      Css.property "font-size" (if current then "4em" else "3em") ]
  in
    div [
      Attributes.css [
        Css.property "background-image" ("linear-gradient("
        ++ (currentSignup |> (executeIfPresent .color defaultBackground) |> renderColor)
        ++ ","
        ++ (defaultBackground |> renderColor)
        ++ ","
        ++ (otherSignup |> (executeIfPresent .color defaultBackground) |> renderColor)
        ++ ")"),
        Css.maxWidth <| Css.em 60,
        Css.height <| Css.pct 100,
        Css.displayFlex,
        Css.property "flex-direction" "column",
        Css.property "justify-content" "space-between"
      ]
    ] [
      --div [] [ text model.errorMessage ],
      div [ playerStyle (isCurrentlyPlaing model.board <| executeIfPresent .playerId 69 otherSignup) ] [ text <| executeIfPresent .userName "None" otherSignup ],
      renderBoard model.board model.signups,
      div [ playerStyle (isCurrentlyPlaing model.board <| executeIfPresent .playerId 69 currentSignup) ] [ text <| executeIfPresent .userName "None" currentSignup ]
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

toDictionaryWithKey : (obj -> comparable) -> List obj -> Dict comparable obj
toDictionaryWithKey func list =
  List.map (\n -> (func n, n)) list |> Dict.fromList


setSelectedStoneId : Maybe Int -> Board -> Board
setSelectedStoneId id board =
  {board | selectedStoneId = id}

isCurrentlyPlaing : Board -> Int -> Bool
isCurrentlyPlaing board playerId =
  case board.currentPlayerId of
    Just currentPlayerId ->
      playerId == currentPlayerId
    Nothing ->
      False

canTouchStone : Model -> Stone -> Bool
canTouchStone model stone =
  case model.role of
    Player playerId ->
      if stone.playerId == playerId && isCurrentlyPlaing model.board playerId then
        True
      else
        False
    _ ->
      False

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
    maybeSelectedStone = Dict.get selectedStoneId model.board.stones
  in
    case maybeSelectedStone of
      Just prevSelectedStone ->
        if canTouchStone model prevSelectedStone then
        (
          {model | board = model.board |> setSelectedStoneId (Nothing)},
          createPlayCommand (prevSelectedStone.x, prevSelectedStone.y) coords
        )
        else
          (model, Cmd.none)
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
          ({model | signups = data |> toDictionaryWithKey .playerId}, Cmd.none)
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
          ({model | board = data}, Cmd.none)
        Err error ->
          ({model | errorMessage = Decode.errorToString error}, Cmd.none)
    StoneClicked stone ->
      case model.board.selectedStoneId of
        Just selectedStoneId ->
          updateToPlayAt model selectedStoneId (stone.x, stone.y)
        Nothing ->
          if canTouchStone model stone then
            ({model | board = model.board |> setSelectedStoneId (Just stone.id)}, Cmd.none)
          else
            (model, Cmd.none)
    FieldClicked coords ->
      case model.board.selectedStoneId of
        Just selectedStoneId ->
          updateToPlayAt model selectedStoneId coords
        Nothing ->
          (model, Cmd.none)

-- SUBSCRIPTIONS

parseStateString : String -> Result String State
parseStateString string =
  case string of
    "playing" ->
      Ok Playing
    "waiting" ->
      Ok Waiting
    "finished" ->
      Ok Finished
    _ ->
      Err "Invalid state string"

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

signupsDecoder : Decode.Decoder (List Signup)
signupsDecoder =
  Decode.list <| (Decode.succeed Signup
    |> DPipeline.required "user_name" Decode.string
    |> DPipeline.required "player_id" Decode.int
    |> DPipeline.required "spent_points" Decode.int
    |> DPipeline.required "color" colorDecoder)

stoneDecoder : Decode.Decoder Stone
stoneDecoder =
  Decode.succeed Stone 
    |> DPipeline.required "id" Decode.int
    |> DPipeline.required "x" Decode.int
    |> DPipeline.required "y" Decode.int
    |> DPipeline.required "player_id" Decode.int


shapesDecoder : Decode.Decoder (List Shape)
shapesDecoder =
  Decode.list <| (Decode.succeed Shape 
    |> DPipeline.required "id" Decode.int
    |> DPipeline.required "player_id" Decode.int
    |> DPipeline.required "name" Decode.string
    |> DPipeline.required "points" Decode.int
    |> DPipeline.required "traded" Decode.bool
    |> DPipeline.requiredAt [ "board_data", "stones" ] (Decode.list stoneDecoder))

boardDecoder : Decode.Decoder Board
boardDecoder =
  Decode.succeed Board
    |> DPipeline.requiredAt [ "board_data", "width" ] Decode.int
    |> DPipeline.requiredAt [ "board_data", "height" ] Decode.int
    |> DPipeline.requiredAt [ "board_data", "stones" ] (Decode.list stoneDecoder |> Decode.andThen (\list -> List.map (\n -> (n.id, n)) list |> Dict.fromList |> Decode.succeed))
    |> DPipeline.required "fulfilled_shapes" shapesDecoder
    |> DPipeline.hardcoded Nothing
    |> DPipeline.required "currently_playing" (Decode.nullable Decode.int)

subscriptions : Model -> Sub Message
subscriptions model =
  Sub.batch [
    statePort (parseStateString >> StateReceived), -- function composure
    signupsPort ((Decode.decodeValue signupsDecoder) >> SignupsReceived), -- decoding a json
    rolePort (decodeRole >> RoleReceived),
    boardPort ((Decode.decodeValue boardDecoder) >> BoardReceived)
  ]

-- MAIN

main : Program Flags Model Message
main =
  Browser.element
    {
      init = init,
      view = view >> Html.Styled.toUnstyled,
      update = update,
      subscriptions = subscriptions
    }
