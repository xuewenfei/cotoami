module App.Server.Amishi exposing
    ( decodeAmishi
    , fetchAmishi
    , fetchAmishiByEmail
    , fetchInvitees
    )

import App.Types.Amishi exposing (Amishi, AmishiId)
import Http
import Json.Decode as Decode exposing (bool, int, list, maybe, string)


decodeAmishi : Decode.Decoder Amishi
decodeAmishi =
    Decode.map7 Amishi
        (Decode.field "id" string)
        (Decode.field "email" (maybe string))
        (Decode.field "auth_provider" (maybe string))
        (Decode.field "owner" bool)
        (Decode.field "avatar_url" string)
        (Decode.field "display_name" string)
        (Decode.field "invite_limit" (maybe int))


fetchAmishi : (Result Http.Error Amishi -> msg) -> AmishiId -> Cmd msg
fetchAmishi tag amishiId =
    Http.send tag <|
        Http.get ("/api/amishis/" ++ amishiId) decodeAmishi


fetchAmishiByEmail : (Result Http.Error Amishi -> msg) -> String -> Cmd msg
fetchAmishiByEmail tag email =
    Http.send tag <|
        Http.get ("/api/amishis/email/" ++ email) decodeAmishi


fetchInvitees : (Result Http.Error (List Amishi) -> msg) -> Cmd msg
fetchInvitees tag =
    Http.send tag <| Http.get "/api/invitees" (list decodeAmishi)
