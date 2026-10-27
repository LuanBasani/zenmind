const fs = require('fs');
const path = require('path');
const os = require('os');
const https = require('https');

// Helper to make HTTPS requests
function fetchJson(url, options = {}) {
  return new Promise((resolve, reject) => {
    const req = https.request(url, options, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          resolve({ status: res.statusCode, data: parsed });
        } catch (e) {
          resolve({ status: res.statusCode, raw: data });
        }
      });
    });
    req.on('error', reject);
    if (options.body) {
      req.write(options.body);
    }
    req.end();
  });
}

// Translate English text to Portuguese (pt-BR)
async function translateToPortuguese(text) {
  try {
    const cleanText = text.replace(/^[0-9]+[\.\-\)]\s*/, '').trim();
    const url = `https://api.mymemory.translated.net/get?q=${encodeURIComponent(cleanText)}&langpair=en|pt-br`;
    const res = await fetchJson(url);
    if (res.status === 200 && res.data && res.data.responseData && res.data.responseData.translatedText) {
      let translated = res.data.responseData.translatedText;
      // Clean up any translation artifacts
      translated = translated.replace(/^[0-9]+[\.\-\)]\s*/, '').trim();
      return translated;
    }
  } catch (err) {
    console.log('⚠️ Não foi possível traduzir via API, mantendo texto original ou fallback.');
  }
  return text;
}

// 1. Fetch quote from public APIs with automatic PT-BR translation and curated fallbacks
async function getDailyQuote() {
  console.log('📡 1. Buscando nova citação de API externa...');

  // Try Quotable API
  try {
    const res = await fetchJson('https://api.quotable.io/quotes/random');
    if (res.status === 200 && (res.data[0] || res.data)) {
      const q = res.data[0] || res.data;
      if (q.content) {
        console.log('✅ Citação obtida com sucesso da API Quotable!');
        console.log('🌐 Traduzindo citação para Português (PT-BR)...');
        const translatedText = await translateToPortuguese(q.content);
        return {
          text: translatedText,
          author: q.author || 'Desconhecido',
        };
      }
    }
  } catch (err) {
    console.log('⚠️ Quotable indisponível, tentando API alternativa (ZenQuotes)...');
  }

  // Try ZenQuotes API
  try {
    const res = await fetchJson('https://zenquotes.io/api/random');
    if (res.status === 200 && Array.isArray(res.data) && res.data[0]) {
      console.log('✅ Citação obtida com sucesso da API ZenQuotes!');
      console.log('🌐 Traduzindo citação para Português (PT-BR)...');
      const translatedText = await translateToPortuguese(res.data[0].q);
      return {
        text: translatedText,
        author: res.data[0].a || 'Desconhecido',
      };
    }
  } catch (err) {
    console.log('⚠️ ZenQuotes indisponível, usando lista curada em Português...');
  }

  // Curated list in Portuguese
  const ptFallbacks = [
    { text: 'A mente que se abre a uma nova ideia jamais voltará ao seu tamanho original.', author: 'Albert Einstein' },
    { text: 'A paz vem de dentro. Não a procure à sua volta.', author: 'Buda' },
    { text: 'Viver é desenhar sem borracha.', author: 'Millôr Fernandes' },
    { text: 'A persistência é o caminho do êxito.', author: 'Charles Chaplin' },
    { text: 'O segredo da mudança é focar toda a sua energia não em lutar contra o velho, mas em construir o novo.', author: 'Sócrates' },
    { text: 'Renda-se, como eu me rendi. Mergulhe no que você não conhece como eu mergulhei.', author: 'Clarice Lispector' },
    { text: 'Tudo o que um sonho precisa para ser realizado é alguém que acredite que ele possa ser realizado.', author: 'Roberto Shinyashiki' },
    { text: 'O que a lagarta chama de fim do mundo, o mestre chama de borboleta.', author: 'Richard Bach' },
    { text: 'Não espere por circunstâncias ideais. Comece agora, exatamente onde você está.', author: 'Marco Aurélio' },
    { text: 'A felicidade não é algo pronto. Ela vem de suas próprias ações.', author: 'Dalai Lama' },
  ];

  const chosen = ptFallbacks[Math.floor(Math.random() * ptFallbacks.length)];
  console.log('✅ Citação selecionada da lista curada em Português!');
  return chosen;
}

// 2. Read and refresh Firebase CLI auth token
async function getFirebaseAccessToken() {
  const configPath = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');
  if (!fs.existsSync(configPath)) {
    throw new Error('Configuração do Firebase CLI não encontrada em ' + configPath);
  }

  const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  const tokens = config.tokens;

  const now = Date.now();
  if (tokens.expires_at && tokens.expires_at > now + 60000 && tokens.access_token) {
    return tokens.access_token;
  }

  console.log('🔄 Renovando token de acesso do Firebase...');
  const postData = new URLSearchParams({
    client_id: '563584335869-fgrhgmd47bqnekij5i8b5pr03ho85qd6.apps.googleusercontent.com',
    grant_type: 'refresh_token',
    refresh_token: tokens.refresh_token,
  }).toString();

  const res = await fetchJson('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Content-Length': Buffer.byteLength(postData),
    },
    body: postData,
  });

  if (res.status === 200 && res.data.access_token) {
    tokens.access_token = res.data.access_token;
    tokens.expires_at = now + res.data.expires_in * 1000;
    fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
    return tokens.access_token;
  } else {
    return tokens.access_token;
  }
}

// 3. Update Firestore document
async function updateFirestore(quote) {
  console.log(`\n💬 Citação em Português:`);
  console.log(`   "${quote.text}"`);
  console.log(`   — ${quote.author}`);

  const token = await getFirebaseAccessToken();
  const projectId = 'gen-lang-client-0621770583';
  const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/dailyContent/quoteOfTheDay`;

  const bodyData = JSON.stringify({
    fields: {
      text: { stringValue: quote.text },
      author: { stringValue: quote.author },
      updatedAt: { timestampValue: new Date().toISOString() },
    },
  });

  console.log('\n🚀 2. Atualizando documento /dailyContent/quoteOfTheDay no Firestore...');
  const res = await fetchJson(url, {
    method: 'PATCH',
    headers: {
      'Authorization': 'Bearer ' + token,
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(bodyData),
    },
    body: bodyData,
  });

  if (res.status === 200) {
    console.log('🎉 SUCESSO! Citação em PT-BR gravada no Firestore.');
    console.log('👉 Veja no BlueStacks: a tela atualizou em tempo real!');
  } else {
    throw new Error(`Erro ao atualizar Firestore (HTTP ${res.status}): ` + JSON.stringify(res.data || res.raw));
  }
}

async function main() {
  console.log('====================================================');
  console.log('🧘 ZenMind - Atualizador da Citação do Dia (PT-BR)');
  console.log('====================================================');
  try {
    const quote = await getDailyQuote();
    await updateFirestore(quote);
    console.log('====================================================\n');
  } catch (error) {
    console.error('❌ Falha:', error.message);
  }
}

main();
