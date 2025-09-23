// src/firebase.js
import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";

const firebaseConfig = {
  apiKey: "AIzaSyCbsSnwC5lGQ3z-sNeHDl9ZhVceU-2EXs4",
  authDomain: "fongshop.firebaseapp.com",
  projectId: "fongshop",
  storageBucket: "fongshop.firebasestorage.app",
  messagingSenderId: "627545192727",
  appId: "1:627545192727:web:d9fe25cf4fc77e5191df52",
  measurementId: "G-0NWPPN17EX",
};

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);

export { auth };
