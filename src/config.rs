use std::net::SocketAddr;

#[derive(Debug, Clone)]
pub struct Config {
    pub database_url: String,
    pub bind_addr: SocketAddr,
}

impl Config {
    pub fn from_env() -> anyhow::Result<Self> {
        dotenvy::dotenv().ok();
        
        let database_url = std::env::var("DATABASE_URL")
            .unwrap_or_else(|_| "sqlite:./portfolio.db".to_string());
        
        let host = std::env::var("HOST")
            .unwrap_or_else(|_| "0.0.0.0".to_string());
        
        let port: u16 = std::env::var("PORT")
            .unwrap_or_else(|_| "8080".to_string())
            .parse()
            .unwrap_or(8080);
        
        let bind_addr = format!("{}:{}", host, port).parse()?;

        Ok(Config {
            database_url,
            bind_addr,
        })
    }
}