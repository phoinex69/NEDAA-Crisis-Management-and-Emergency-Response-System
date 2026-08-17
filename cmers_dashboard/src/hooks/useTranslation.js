import { useSyncExternalStore } from 'react';
import translations from '../utils/translations';

const LANGUAGE_KEY = 'cmers_language';
const listeners = new Set();

export function getLanguage() {
  return localStorage.getItem(LANGUAGE_KEY) ?? 'en';
}

export function setLanguage(lang) {
  localStorage.setItem(LANGUAGE_KEY, lang);
  listeners.forEach((listener) => listener());
}

function subscribe(callback) {
  listeners.add(callback);
  return () => listeners.delete(callback);
}

export function useTranslation() {
  const language = useSyncExternalStore(subscribe, getLanguage);

  function t(key) {
    return translations[language]?.[key] ?? translations.en[key] ?? key;
  }

  return { t, language, setLanguage, isRTL: language === 'ar' };
}
