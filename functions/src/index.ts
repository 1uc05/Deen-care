// How  to use:
// 1. cd functions
// 2. npm run build
// 3. cd ..
// 4. firebase deploy --only functions

import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import { ChatTokenBuilder } from 'agora-token';
import { RtcTokenBuilder, RtcRole } from 'agora-token';
import fetch from 'node-fetch'; 

admin.initializeApp();

// Configuration Agora avec functions.config()
const config = functions.config();
const APP_ID = config.agora.app_id;
const APP_CERTIFICATE = config.agora.app_certificate;
const ORG_NAME = config.agora.org_name;
const APP_NAME = config.agora.app_name;
// const AGORA_BASE_URL = `https://a611.chat.agora.io/${ORG_NAME}/${APP_NAME}`;
const AGORA_BASE_URL = `https://a71.chat.agora.io`;

// Cache pour le token d'application
let cachedAppToken: { token: string; expiresAt: number } | null = null;

function getAppToken(): string {
  const now = Math.floor(Date.now() / 1000);
  
  if (cachedAppToken && cachedAppToken.expiresAt > now + 300) {
    return cachedAppToken.token;
  }

  const expireTimeInSeconds = 3600;
  const token = ChatTokenBuilder.buildAppToken(APP_ID, APP_CERTIFICATE, expireTimeInSeconds);
  
  cachedAppToken = {
    token,
    expiresAt: now + expireTimeInSeconds
  };

  return token;
}

export const generateAgoraChatToken = functions
    .region('europe-west1')
    .https.onCall(async (data, context) => {
 
    if (!context.auth?.uid) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const userId = context.auth.uid.toLowerCase();
    const expireTimeInSeconds = 3600;

    try {
      const userDoc = await admin.firestore()
        .collection('users')
        .doc(context.auth.uid)
        .get();

      if (!userDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'User not found in database');
      }

      const token = ChatTokenBuilder.buildUserToken(
        APP_ID,
        APP_CERTIFICATE,
        userId,
        expireTimeInSeconds
      );

      const expirationTime = Math.floor(Date.now() / 1000) + expireTimeInSeconds;

      return { 
        token, 
        expirationTime,
        userId
      };
      
    } catch (error) {
      console.error('Error generating Agora Chat token:', error);
      throw new functions.https.HttpsError('internal', 'Failed to generate chat token');
    }
});



export const addAgoraUser = functions
  .region('europe-west1')
  .https.onCall(async (data, context) => {
        console.log('Adding Agora user...');
    

    if (!context.auth?.uid) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const userId = context.auth.uid.toLowerCase();
    
    try {
      const appToken = getAppToken();

      const response = await fetch(`${AGORA_BASE_URL}/users`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${appToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify([{
          username: userId,
          password: `pwd_${userId}_${Date.now()}`,
          nickname: userId
        }])
      });

      if (!response.ok) {
        const errorText = await response.text();
        
        if (response.status === 400 && errorText.includes('username already exists')) {
          console.log(`Agora user ${userId} already exists`);
          return { 
            success: true, 
            message: 'User already exists',
            userId
          };
        }
        
        throw new Error(`Agora API error: ${response.status} - ${errorText}`);
      }

      const result = await response.json();
      console.log(`Agora user created successfully:`, result);

      return { 
        success: true, 
        message: 'User created successfully',
        userId,
        agoraResponse: result
      };
      
    } catch (error) {
      console.error('Error creating Agora user:', error);
      throw new functions.https.HttpsError('internal', 'Failed to create Agora user');
    }
  });

export const testAuth = functions
    .region('europe-west1')
    .https.onCall(async (data, context) => {
        // console.log('TEST TEST FUNCTION CALLED');
        // console.log('TEST Auth exists:', !!context.auth);
        // console.log('TEST User ID:', context.auth?.uid);
        
        // return {
        //     success: true,
        //     userId: context.auth?.uid || 'not-authenticated',
        //     timestamp: new Date().toISOString()
        // };



    if (!context.auth?.uid) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const userId = context.auth.uid.toLowerCase();
    const expireTimeInSeconds = 3600;

    try {
      const userDoc = await admin.firestore()
        .collection('users')
        .doc(context.auth.uid)
        .get();

      if (!userDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'User not found in database');
      }

      const token = ChatTokenBuilder.buildUserToken(
        APP_ID,
        APP_CERTIFICATE,
        userId,
        expireTimeInSeconds
      );

      const expirationTime = Math.floor(Date.now() / 1000) + expireTimeInSeconds;

      return { 
        token, 
        expirationTime,
        userId
      };
      
    } catch (error) {
      console.error('Error generating Agora Chat token:', error);
      throw new functions.https.HttpsError('internal', 'Failed to generate chat token');
    }
});


export const addUser = functions
  .region('europe-west1')
  .https.onCall(async (data, context) => {
    console.log('Adding Agora user...');
    
    if (!context.auth?.uid) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const userId = context.auth.uid.toLowerCase();
    
    try {
      const appToken = getAppToken();
      const endpoint = `${AGORA_BASE_URL}/${ORG_NAME}/${APP_NAME}/users`;

      const response = await fetch(endpoint, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${appToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify([{
          username: userId,
          password: `pwd_${userId}_${Date.now()}`,
          nickname: userId
        }])
      });

      if (!response.ok) {
        const errorText = await response.text();
        console.log('Agora API response:', errorText);
        
        if (response.status === 400) {
          try {
            const errorJson = JSON.parse(errorText);
            if (errorJson.error === 'duplicate_unique_property_exists' || 
                errorText.includes('username') || 
                errorText.includes('exists')) {
              console.log(`Agora user ${userId} already exists`);
              return { 
                success: true, 
                message: 'User already exists',
                userId,
                isExisting: true
              };
            }
          } catch (parseError) {
            // Si le JSON parse échoue, vérifie avec includes
            if (errorText.includes('duplicate') || 
                errorText.includes('exists') || 
                errorText.includes('username')) {
              console.log(`Agora user ${userId} already exists (fallback check)`);
              return { 
                success: true, 
                message: 'User already exists',
                userId,
                isExisting: true
              };
            }
          }
        }
        
        throw new Error(`Agora API error: ${response.status} - ${errorText}`);
      }

      const result = await response.json();
      console.log(`Agora user created successfully:`, result);

      return { 
        success: true, 
        message: 'User created successfully',
        userId,
        agoraResponse: result,
        isExisting: false
      };
      
    } catch (error) {
      console.error('Error creating Agora user:', error);
      throw new functions.https.HttpsError('internal', `Failed to create Agora user`);
    }
  });

  
export const getRtcToken = functions
  .region('europe-west1')
  .https.onCall(async (data, context) => {
    console.log('Creating Agora RTC token...');


    if (!context.auth?.uid) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { channelName } = data;

    if (!channelName) {
      throw new functions.https.HttpsError('invalid-argument', 'channelName is required');
    }

    try {
      const userDoc = await admin.firestore()
        .collection('users')
        .doc(context.auth.uid)
        .get();

      if (!userDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'User not found in database');
      }

      const uid = 0; // 0 = auto-assigné par Agora
      const expireTimeInSeconds = 3600;
      const currentTimestamp = Math.floor(Date.now() / 1000);
      const tokenExpire = currentTimestamp + expireTimeInSeconds;
      const privilegeExpire = currentTimestamp + expireTimeInSeconds;


      // Token RTC avec permissions Broadcaster
      const token = RtcTokenBuilder.buildTokenWithUid(
        APP_ID,
        APP_CERTIFICATE,
        channelName,
        uid,
        RtcRole.PUBLISHER, // Peut parler et écouter
        tokenExpire,
        privilegeExpire
      );

      return { 
        token, 
        expirationTime: tokenExpire,
        channelName,
        uid: 0
      };
      
    } catch (error) {
      console.error('Error generating Agora RTC token:', error);
      throw new functions.https.HttpsError('internal', 'Failed to generate RTC token');
    }
  });

