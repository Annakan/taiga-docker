config = {
#    host: "${hostname}"
    host: "docker.assemblee-nationale.fr"
#    scheme: "${scheme}"
    scheme: "http"

    debug: true

    defaultLanguage: "en"
    languageOptions: {
        "en": "English"
    }

    publicRegisterEnabled: false
    privacyPolicyUrl: null
    termsOfServiceUrl: null
}

angular.module("taigaLocalConfig", []).value("localconfig", config)
