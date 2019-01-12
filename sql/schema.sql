
CREATE TABLE accounts (
       id serial PRIMARY KEY,
       active boolean NOT NULL DEFAULT true,
       twitch_id bigint UNIQUE,
       discord_id bigint UNIQUE,

       created_time timestamptz NOT NULL DEFAULT now()
);

INSERT INTO accounts (id) VALUES (0);

CREATE TABLE coins (
       id serial PRIMARY KEY,

       discord_token text,
       discord_client_id text,
       twitch_token text,

       prefix text NOT NULL,

       dbl_auth text,
       dbl_stats text,
       botsgg_token text,

       admins bigint[],
       ignored_users bigint[],
       whitelisted_bots bigint[],

       rpc_url text NOT NULL,
       rpc_username text NOT NULL,
       rpc_password text NOT NULL,

       uri_scheme text NOT NULL,

       tx_fee numeric(64, 8) NOT NULL,

       name_short text NOT NULL,
       name_long text NOT NULL,

       default_min_soak numeric(64, 8) NOT NULL,
       default_min_soak_total numeric(64, 8) NOT NULL,

       default_min_rain numeric(64, 8) NOT NULL,
       default_min_rain_total numeric(64, 8) NOT NULL,

       default_min_tip numeric(64, 8) NOT NULL,
       default_min_lucky numeric(64, 8) NOT NULL,

       high_balance numeric(64, 8) NOT NULL,

       created_time timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE balances (
       account_id bigint NOT NULL REFERENCES accounts(id),
       coin int NOT NULL REFERENCES coins(id),
       balance numeric(64, 8) NOT NULL CONSTRAINT positive_amount CHECK (balance >= 0),
       PRIMARY KEY (account_id, coin)
);

CREATE TYPE transaction_memo AS ENUM('DEPOSIT', 'LUCKY', 'TIP', 'SOAK', 'RAIN', 'WITHDRAWAL', 'SPONSORED', 'DONATION', 'IMPORT_FOR_LINK');
CREATE TABLE transactions (
       id serial PRIMARY KEY,
       coin int NOT NULL REFERENCES coins(id),
       memo transaction_memo NOT NULL,
       account_id bigint NOT NULL REFERENCES accounts(id),
       amount numeric(64, 8) NOT NULL,

       address text,
       coin_transaction_id text,

       time timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE guilds (
    id bigint PRIMARY KEY,
    coin int NOT NULL REFERENCES coins,
    UNIQUE(id, coin),

    contacted boolean NOT NULL DEFAULT false,

    created_time timestamptz NOT NULL DEFAULT now(),

    prefix text,

    mention boolean NOT NULL DEFAULT false,
    soak boolean NOT NULL DEFAULT false,
    rain boolean NOT NULL DEFAULT false,

    min_soak numeric(64, 8),
    min_soak_total numeric(64, 8),

    min_rain numeric(64, 8),
    min_rain_total numeric(64, 8),

    min_tip numeric(64, 8),
    min_lucky numeric(64, 8)
);

CREATE TYPE deposit_status AS ENUM('NEW', 'CREDITED', 'NEVER');
CREATE TABLE deposits (
       txhash text PRIMARY KEY,
       status deposit_status NOT NULL,
       user_id bigint,

       created_time timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE withdrawals (
       id serial PRIMARY KEY,
       pending boolean DEFAULT true,
       from_id bigint NOT NULL REFERENCES accounts(id),
       address text NOT NULL,
       amount numeric(64, 8) CONSTRAINT positive_amount CHECK (amount > 0),

       created_time timestamptz NOT NULL DEFAULT now()
);

CREATE MATERIALIZED VIEW statistics AS (
       SELECT
              (SELECT SUM(1) FROM transactions) AS transaction_count,
              (SELECT SUM(amount) FROM transactions) AS transaction_sum,
              (SELECT SUM(amount) FROM transactions WHERE memo='TIP') AS tip_sum,
              (SELECT SUM(amount) FROM transactions WHERE memo='SOAK') AS soak_sum,
              (SELECT SUM(amount) FROM transactions WHERE memo='RAIN') as rain_sum
);


CREATE TYPE offsite_memo AS ENUM ('DEPOSIT', 'WITHDRAWAL');
CREATE TABLE offsite (
	id serial PRIMARY KEY,

	memo offsite_memo NOT NULL,
	user_id bigint NOT NULL REFERENCES accounts(id),

	amount numeric(64, 8) CONSTRAINT positive_amount CHECK (amount > 0),
	created_time timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX offsite_user_id ON offsite USING btree (user_id);

CREATE TABLE offsite_addresses (
	id serial PRIMARY KEY,

	address text NOT NULL,

	user_id bigint NOT NULL REFERENCES accounts(id),
	created_time timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX offsite_addresses_user_id ON offsite_addresses USING btree(user_id);
CREATE INDEX offsite_addresses_address ON offsite_addresses USING btree(address);
