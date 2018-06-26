package com.oltpbenchmark.benchmarks.twitter;

public abstract class TwitterConstants {

    public static final String TABLENAME_USER           = "user_profiles";
    public static final String TABLENAME_TWEETS         = "tweets";
    public static final String TABLENAME_FOLLOWS        = "follows";
    public static final String TABLENAME_FOLLOWERS      = "followers";
    public static final String TABLENAME_ADDED_TWEETS   = "added_tweets";
    
	/**
	 * Number of user baseline
	 */
    public static final int NUM_USERS = 500; 
    
    /**
     * Number of tweets baseline
     */
    public static final int NUM_TWEETS = 20000; 
    
    /**
     * Max follow per user baseline
     */
    public static final int MAX_FOLLOW_PER_USER = 50;

    /**
     * Message length (inclusive)
     */
    public static final int MAX_TWEET_LENGTH = 140;
    
    /**
     * Name length (inclusive)
     */
    public static final int MIN_NAME_LENGTH = 3;
    public static final int MAX_NAME_LENGTH = 20;
    // TODO: make the next parameters of WorkLoadConfiguration
    public static int LIMIT_TWEETS = 100;
    public static int LIMIT_TWEETS_FOR_UID = 10;
    public static int LIMIT_FOLLOWERS = 10; 
    public static int LIMIT_FOLLOWING = 10; 
    
    public static final int FREQ_GET_TWEET = 0; // HACK - was 1
    public static final int FREQ_GET_TWEETS_FROM_FOLLOWING = 1;
    public static final int FREQ_GET_FOLLOWERS = 3;
    public static final int FREQ_GET_USER_TWEETS = 90; // HACK - was 89
    public static final int FREQ_INSERT_TWEET = 6;
    public static final String USE_GRAPH_TXN_GEN = "USE_GRAPH_TXN_GEN";
    public static final boolean USE_GRAPH_TXN_GEN_DEFAULT = false;

	
}