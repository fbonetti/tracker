module Main where

import Task exposing (Task, andThen)
import SocketIO
import Json.Decode as Json exposing ((:=))
import Result
import Html exposing (Html, text, div)
import Dict exposing (Dict)

-- MAIN

main : Signal Html
main =
  (Signal.foldp update initModel >> Signal.map view) mainSignal

mainSignal : Signal Action
mainSignal =
  Signal.mergeMany
    [ readings
    ]

-- MODEL

initModel : Model
initModel = Model (Dict.fromList [])

type alias Model =
  { readings : Dict String Reading
  }

type alias Reading =
  { id : String
  , latitude : Float
  , longitude : Float
  }

-- SOCKET

socket : Task x SocketIO.Socket
socket = SocketIO.io "http://localhost:8050" SocketIO.defaultOptions

eventName : String
eventName = "reading"

port readingsSocket : Task x ()
port readingsSocket = socket `andThen` SocketIO.on eventName received.address

received : Signal.Mailbox String
received = Signal.mailbox "null"

readingDecoder : Json.Decoder Reading
readingDecoder =
  Json.object3 Reading
    ("id" := Json.string)
    ("latitude" := Json.float)
    ("longitude" := Json.float)

readings : Signal Action
readings =
  let
    handleResult result =
      case result of
        Ok reading -> AddReading reading
        Err _ -> NoOp
  in
    Signal.map
      (Json.decodeString readingDecoder >> handleResult)
      received.signal

-- UPDATE

type Action
    = AddReading Reading
    | NoOp

update : Action -> Model -> Model
update action model =
  case action of
    AddReading reading ->
      if Dict.member reading.id model.readings then
        model
      else
        { model | readings = Dict.insert reading.id reading model.readings }
    NoOp ->
      model

-- VIEW

view : Model -> Html
view model =
  div [] (model.readings |> Dict.values |> List.map (toString >> text))

