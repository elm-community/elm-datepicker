module Range exposing (main)

import Date exposing (Date, Day(..), day, dayOfWeek, month, year)
import DatePicker exposing (defaultSettings, DateEvent(..))
import Html exposing (Html, div, h1, text)


type Msg
    = ToStartDatePicker DatePicker.Msg
    | ToEndDatePicker DatePicker.Msg


type alias Model =
    { startDate : Maybe Date
    , endDate : Maybe Date
    , startDatePicker : DatePicker.DatePicker
    , endDatePicker : DatePicker.DatePicker
    }



-- Could be used to customize common settings for both date pickers. Like for
-- example disabling weekends from them.


commonSettings : DatePicker.Settings
commonSettings =
    defaultSettings



-- Extend commonSettings with isDisabled function which would disable dates
-- after already selected end date because range start should come before end.


startSettings : Maybe Date -> DatePicker.Settings
startSettings endDate =
    let
        isDisabled =
            case endDate of
                Nothing ->
                    commonSettings.isDisabled

                Just endDate ->
                    \d ->
                        Date.toTime d
                            > Date.toTime endDate
                            || (commonSettings.isDisabled d)
    in
        { commonSettings
            | placeholder = "Pick a start date"
            , isDisabled = isDisabled
        }



-- Extend commonSettings with isDisabled function which would disable dates
-- before already selected start date because range end should come after start.


endSettings : Maybe Date -> DatePicker.Settings
endSettings startDate =
    let
        isDisabled =
            case startDate of
                Nothing ->
                    commonSettings.isDisabled

                Just startDate ->
                    \d ->
                        Date.toTime d
                            < Date.toTime startDate
                            || (commonSettings.isDisabled d)
    in
        { commonSettings
            | placeholder = "Pick an end date"
            , isDisabled = isDisabled
        }


init : ( Model, Cmd Msg )
init =
    let
        ( startDatePicker, startDatePickerFx ) =
            DatePicker.init

        ( endDatePicker, endDatePickerFx ) =
            DatePicker.init
    in
        { startDate = Nothing
        , startDatePicker = startDatePicker
        , endDate = Nothing
        , endDatePicker = endDatePicker
        }
            ! ([ Cmd.map ToStartDatePicker startDatePickerFx ]
                ++ [ Cmd.map
                        ToEndDatePicker
                        endDatePickerFx
                   ]
              )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ToStartDatePicker msg ->
            let
                ( newDatePicker, datePickerFx, dateEvent ) =
                    DatePicker.update (startSettings model.endDate) msg model.startDatePicker

                newDate =
                    case dateEvent of
                        Changed newDate ->
                            newDate

                        _ ->
                            model.startDate
            in
                { model
                    | startDate = newDate
                    , startDatePicker = newDatePicker
                }
                    ! [ Cmd.map ToStartDatePicker datePickerFx ]

        ToEndDatePicker msg ->
            let
                ( newDatePicker, datePickerFx, dateEvent ) =
                    DatePicker.update (endSettings model.startDate) msg model.endDatePicker

                newDate =
                    case dateEvent of
                        Changed newDate ->
                            newDate

                        _ ->
                            model.endDate
            in
                { model
                    | endDate = newDate
                    , endDatePicker = newDatePicker
                }
                    ! [ Cmd.map ToEndDatePicker datePickerFx ]


view : Model -> Html Msg
view model =
    div []
        [ viewRange model.startDate model.endDate
        , DatePicker.view model.startDate (startSettings model.endDate) model.startDatePicker
            |> Html.map ToStartDatePicker
        , DatePicker.view model.endDate (endSettings model.startDate) model.endDatePicker
            |> Html.map ToEndDatePicker
        ]


viewRange : Maybe Date -> Maybe Date -> Html Msg
viewRange start end =
    case ( start, end ) of
        ( Nothing, Nothing ) ->
            h1 [] [ text "Pick dates" ]

        ( Just start, Nothing ) ->
            h1 [] [ text <| formatDate start ++ " – Pick end date" ]

        ( Nothing, Just end ) ->
            h1 [] [ text <| "Pick start date – " ++ formatDate end ]

        ( Just start, Just end ) ->
            h1 [] [ text <| formatDate start ++ " – " ++ formatDate end ]


formatDate : Date -> String
formatDate d =
    toString (month d) ++ " " ++ toString (day d) ++ ", " ++ toString (year d)


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = always Sub.none
        }
