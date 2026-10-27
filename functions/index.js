const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onRequest} = require("firebase-functions/v2/https");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const axios = require("axios");

initializeApp();

// ---------------------------------------------------------------------------
// Cloud Function Agendada (Scheduled)
// Executa todos os dias às 00:01 (Horário de Brasília) para atualizar a citação
// ---------------------------------------------------------------------------
exports.updateQuoteOfTheDay = onSchedule(
  {
    schedule: "1 0 * * *",
    timeZone: "America/Sao_Paulo",
    retryConfig: {retryCount: 3},
  },
  async (event) => {
    await fetchAndSaveQuote();
  },
);

// ---------------------------------------------------------------------------
// Trigger HTTP Manual (Para testes rápidos de integração)
// ---------------------------------------------------------------------------
exports.updateQuoteManual = onRequest(async (req, res) => {
  try {
    await fetchAndSaveQuote();
    res.status(200).json({message: "Citação atualizada com sucesso em PT-BR!"});
  } catch (error) {
    console.error("Erro ao atualizar citação manualmente:", error);
    res.status(500).json({error: "Falha ao atualizar citação"});
  }
});

// ---------------------------------------------------------------------------
// Lógica Principal de Busca e Tradução para PT-BR
// ---------------------------------------------------------------------------

async function translateToPortuguese(text) {
  try {
    const cleanText = text.replace(/^[0-9]+[\.\-\)]\s*/, "").trim();
    const url = `https://api.mymemory.translated.net/get?q=${encodeURIComponent(cleanText)}&langpair=en|pt-br`;
    const res = await axios.get(url, {timeout: 8000});
    if (res.data && res.data.responseData && res.data.responseData.translatedText) {
      let translated = res.data.responseData.translatedText;
      return translated.replace(/^[0-9]+[\.\-\)]\s*/, "").trim();
    }
  } catch (err) {
    console.warn("Tradução automática falhou, usando texto original ou fallback.");
  }
  return text;
}

async function fetchAndSaveQuote() {
  const db = getFirestore();

  try {
    // 1. Tentar API Quotable
    const response = await axios.get(
      "https://api.quotable.io/quotes/random",
      {timeout: 10000},
    );

    const quoteData = response.data[0] || response.data;
    if (!quoteData || !quoteData.content) {
      throw new Error("Dados inválidos da API Quotable");
    }

    const translatedText = await translateToPortuguese(quoteData.content);

    const quote = {
      text: translatedText,
      author: quoteData.author || "Desconhecido",
      updatedAt: new Date(),
      source: "quotable.io (PT-BR)",
    };

    await db.collection("dailyContent").doc("quoteOfTheDay").set(quote);
    console.log(`Citação do dia atualizada: "${quote.text}" — ${quote.author}`);
    return;
  } catch (error) {
    console.warn("Falha na Quotable, tentando ZenQuotes API:", error.message);
  }

  try {
    // 2. Tentar API ZenQuotes
    const zenRes = await axios.get("https://zenquotes.io/api/random", {
      timeout: 10000,
    });
    if (zenRes.data && Array.isArray(zenRes.data) && zenRes.data[0]) {
      const translatedText = await translateToPortuguese(zenRes.data[0].q);
      const quote = {
        text: translatedText,
        author: zenRes.data[0].a || "Desconhecido",
        updatedAt: new Date(),
        source: "zenquotes.io (PT-BR)",
      };
      await db.collection("dailyContent").doc("quoteOfTheDay").set(quote);
      console.log(`Citação salva via ZenQuotes: "${quote.text}" — ${quote.author}`);
      return;
    }
  } catch (zenError) {
    console.warn("ZenQuotes também falhou, usando lista curada em Português:", zenError.message);
  }

  // 3. Fallback: Coleção curada em Português de grandes pensadores
  const ptFallbacks = [
    {text: "A mente que se abre a uma nova ideia jamais voltará ao seu tamanho original.", author: "Albert Einstein"},
    {text: "A paz vem de dentro. Não a procure à sua volta.", author: "Buda"},
    {text: "Viver é desenhar sem borracha.", author: "Millôr Fernandes"},
    {text: "A persistência é o caminho do êxito.", author: "Charles Chaplin"},
    {text: "O segredo da mudança é focar toda a sua energia não em lutar contra o velho, mas em construir o novo.", author: "Sócrates"},
    {text: "Renda-se, como eu me rendi. Mergulhe no que você não conhece como eu mergulhei.", author: "Clarice Lispector"},
    {text: "Tudo o que um sonho precisa para ser realizado é alguém que acredite que ele possa ser realizado.", author: "Roberto Shinyashiki"},
    {text: "O que a lagarta chama de fim do mundo, o mestre chama de borboleta.", author: "Richard Bach"},
    {text: "Não espere por circunstâncias ideais. Comece agora, exatamente onde você está.", author: "Marco Aurélio"},
    {text: "A felicidade não é algo pronto. Ela vem de suas próprias ações.", author: "Dalai Lama"},
  ];

  const randomQuote = ptFallbacks[Math.floor(Math.random() * ptFallbacks.length)];
  const quote = {
    text: randomQuote.text,
    author: randomQuote.author,
    updatedAt: new Date(),
    source: "curated-pt-br",
  };

  await db.collection("dailyContent").doc("quoteOfTheDay").set(quote);
  console.log(`Citação de fallback PT-BR salva: "${quote.text}" — ${quote.author}`);
}
