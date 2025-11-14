package configs

import (
	"github.com/spf13/viper"
)

type ENV struct {
	GRPC_SERVER_ADDRESS         string `mapstructure:"GRPC_SERVER_ADDRESS"`
	GRPC_GATEWAY_SERVER_ADDRESS string `mapstructure:"GRPC_GATEWAY_SERVER_ADDRESS"`
	HTTP_SERVER_ADDRESS         string `mapstructure:"HTTP_SERVER_ADDRESS"`
}

func ENVConfig(path string) (config ENV, err error) {
	viper.AddConfigPath(path)
	viper.SetConfigFile(".env")
	viper.SetConfigType("env")
	viper.AutomaticEnv()

	if err = viper.ReadInConfig(); err != nil {
		return
	}

	err = viper.Unmarshal(&config)
	return
}
