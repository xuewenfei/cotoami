module Utils.DateUtil exposing (format, formatDay, sameDay)

import Date exposing (Date, day, month, year)
import Date.Extra.Config.Configs as Configs
import Date.Extra.Format


langToLocaleId : String -> String
langToLocaleId lang =
    case lang of
        "ja" ->
            "ja_jp"

        "ja-jp" ->
            "ja_jp"

        "ru" ->
            "ru_ru"

        "ru-RU" ->
            "ru_ru"

        _ ->
            lang


format : String -> String -> Date -> String
format lang format date =
    let
        config =
            Configs.getConfig (langToLocaleId lang)
    in
    Date.Extra.Format.format config format date


formatDay : String -> Date -> String
formatDay lang date =
    let
        config =
            Configs.getConfig (langToLocaleId lang)
    in
    Date.Extra.Format.format config config.format.longDate date


sameDay : Maybe Date -> Maybe Date -> Bool
sameDay date1 date2 =
    Maybe.map2
        (\d1 d2 ->
            (year d1 == year d2) && (month d1 == month d2) && (day d1 == day d2)
        )
        date1
        date2
        |> Maybe.withDefault False
