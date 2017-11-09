
module Hello exposing (..)


import Html exposing ( text
                     , div
                     , textarea
                     , h1
                     , form
                     , header
                     , body
                     , p
                     )
import Html.Attributes exposing ( style
                                , placeholder
                                , cols
                                , rows
                                )
import Html.Events exposing ( onInput
                            )
import Http
import Debug

import Json.Decode exposing ( Decoder
                            , int
                            , string
                            , list
                            )
import Json.Decode.Pipeline exposing (decode, required)
import Json.Encode as Encode


-- | Types

type alias Model =
    { program : String
    , report  : String
    }

type Msg
    = Program String
    | Analysis String
    | NewReport (Result Http.Error Report)

type Report
    = Report (List String) (List String)


-- | Model

codeEncoder : String -> Encode.Value
codeEncoder code =
    let attributes =
            [ ("code", Encode.string code) ]
    in Encode.object attributes

reportDecoder : Decoder Report
reportDecoder =
    decode Report
        |> required "suggestions" (list string)
        |> required "errors" (list string)

doAnalysis : String -> Cmd Msg
doAnalysis code =
    let url = "http://localhost:8080/scheme/analysis/"
    in Http.send NewReport
        ( Http.post
              url
              (Http.jsonBody (codeEncoder code))
              reportDecoder
        )


update : Msg -> Model -> (Model, Cmd Msg)
update msg model
    = case msg of
          Program p ->
              ({ model | program = p }, Cmd.none)
          Analysis s ->
              ({model | program = s}, doAnalysis model.program)
          NewReport (Ok (Report suggestions errors)) ->
              Debug.log (toString msg) ({ model | report = toString (suggestions ++ errors)}, Cmd.none)
          NewReport (Err err) ->
              Debug.log (toString msg)  ({ model | report = toString err}, Cmd.none)

-- | Subscriptions

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none

-- | Views

textInput : Html.Html Msg
textInput =
    div [  ]
        [ textarea [ placeholder "Enter program"
                   , onInput (\s -> Analysis s)
                   , cols 80
                   , rows 40
                   , style [ ("resize", "vertical") ]
                   ] [ ]
        ]

mainPage : Model -> Html.Html Msg
mainPage model =
    let leftCol  = div [  ] [  ]
        rightCol = div [  ]
                       [
                       ]
    in div [ ]
           [ leftCol
           , div [  ]
               [ header [  ]
                     [ h1 [  ]
                          [ text "Enter Program" ]
                     ]
               , body [  ]
                   [ form [  ]
                         [ textInput
                         ]
                   , p [  ]
                       [ text model.report ]
                   ]
               ]
           , rightCol
           ]

view : Model -> Html.Html Msg
view model =
    mainPage model


-- | Main

init : (Model, Cmd Msg)
init =
    ( initialModel
    , Cmd.none
    )

initialModel : Model
initialModel =
    { program = ""
    , report = "Analysis will be here"
    }

main =
  Html.program { init = init
               , view   = view
               , update = update
               , subscriptions = subscriptions
               }
