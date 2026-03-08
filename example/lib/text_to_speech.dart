import 'dart:async';

import 'package:ailia_voice/ailia_voice.dart' as ailia_voice_dart;
import 'package:ailia_voice/ailia_voice_model.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:wav/wav.dart';

import 'package:flutter/services.dart';

import 'dart:typed_data';

import 'utils/download_model.dart';

class Speaker {
  void play(AiliaVoiceResult audio, String outputPath) async {
    Float64List channel = Float64List(audio.pcm.length);
    for (int i = 0; i < channel.length; i++) {
      channel[i] = audio.pcm[i];
    }

    List<Float64List> channels = List<Float64List>.empty(growable: true);
    channels.add(channel);

    Wav wav = Wav(channels, audio.sampleRate, WavFormat.pcm16bit);

    await wav.writeFile(outputPath);

    final player = AudioPlayer();
    await player.play(DeviceFileSource(outputPath));
  }
}

class TextToSpeech {
  final _speaker = Speaker();
  final _ailiaVoiceModel = AiliaVoiceModel();

  static const int MODEL_TYPE_TACOTRON2 = 0;
  static const int MODEL_TYPE_GPT_SOVITS_JA = 1;
  static const int MODEL_TYPE_GPT_SOVITS_EN = 2;
  static const int MODEL_TYPE_GPT_SOVITS_ZH = 3;
  static const int MODEL_TYPE_GPT_SOVITS_V2_JA = 4;
  static const int MODEL_TYPE_GPT_SOVITS_V2_EN = 5;
  static const int MODEL_TYPE_GPT_SOVITS_V2_ZH = 6;
  static const int MODEL_TYPE_GPT_SOVITS_V3_JA = 7;
  static const int MODEL_TYPE_GPT_SOVITS_V3_EN = 8;
  static const int MODEL_TYPE_GPT_SOVITS_V3_ZH = 9;
  static const int MODEL_TYPE_GPT_SOVITS_V2_PRO_JA = 10;
  static const int MODEL_TYPE_GPT_SOVITS_V2_PRO_EN = 11;
  static const int MODEL_TYPE_GPT_SOVITS_V2_PRO_ZH = 12;

  bool isGPTSoVITS(int modelType) {
    return modelType != MODEL_TYPE_TACOTRON2;
  }

  bool isJA(int modelType) {
    return modelType == MODEL_TYPE_GPT_SOVITS_JA ||
        modelType == MODEL_TYPE_GPT_SOVITS_V2_JA ||
        modelType == MODEL_TYPE_GPT_SOVITS_V3_JA ||
        modelType == MODEL_TYPE_GPT_SOVITS_V2_PRO_JA;
  }

  bool isEN(int modelType) {
    return modelType == MODEL_TYPE_GPT_SOVITS_EN ||
        modelType == MODEL_TYPE_GPT_SOVITS_V2_EN ||
        modelType == MODEL_TYPE_GPT_SOVITS_V3_EN ||
        modelType == MODEL_TYPE_GPT_SOVITS_V2_PRO_EN;
  }

  bool isZH(int modelType) {
    return modelType == MODEL_TYPE_GPT_SOVITS_ZH ||
        modelType == MODEL_TYPE_GPT_SOVITS_V2_ZH ||
        modelType == MODEL_TYPE_GPT_SOVITS_V3_ZH ||
        modelType == MODEL_TYPE_GPT_SOVITS_V2_PRO_ZH;
  }

  bool isV1(int modelType) {
    return modelType == MODEL_TYPE_GPT_SOVITS_JA ||
        modelType == MODEL_TYPE_GPT_SOVITS_EN ||
        modelType == MODEL_TYPE_GPT_SOVITS_ZH;
  }

  bool isV2(int modelType) {
    return modelType == MODEL_TYPE_GPT_SOVITS_V2_JA ||
        modelType == MODEL_TYPE_GPT_SOVITS_V2_EN ||
        modelType == MODEL_TYPE_GPT_SOVITS_V2_ZH;
  }

  bool isV3(int modelType) {
    return modelType == MODEL_TYPE_GPT_SOVITS_V3_JA ||
        modelType == MODEL_TYPE_GPT_SOVITS_V3_EN ||
        modelType == MODEL_TYPE_GPT_SOVITS_V3_ZH;
  }

  bool isV2Pro(int modelType) {
    return modelType == MODEL_TYPE_GPT_SOVITS_V2_PRO_JA ||
        modelType == MODEL_TYPE_GPT_SOVITS_V2_PRO_EN ||
        modelType == MODEL_TYPE_GPT_SOVITS_V2_PRO_ZH;
  }

  bool needsChineseBert(int modelType) {
    return isV2(modelType) || isV3(modelType) || isV2Pro(modelType);
  }

  bool needsG2PW(int modelType) {
    return (isV3(modelType) || isV2Pro(modelType)) ||
        (isV2(modelType) && isZH(modelType));
  }

  bool needsCN(int modelType) {
    return isZH(modelType) || isV3(modelType) || isV2Pro(modelType);
  }

  String getModelFolder(int modelType) {
    if (isV1(modelType)) return "gpt-sovits";
    if (isV2(modelType)) return "gpt-sovits-v2";
    if (isV3(modelType)) return "gpt-sovits-v3";
    if (isV2Pro(modelType)) return "gpt-sovits-v2-pro";
    return "tacotron2";
  }

  List<String> getModelList(int modelType) {
    List<String> modelList = List<String>.empty(growable: true);

    // OpenJTalk辞書（全GPT-SoVITS + Tacotron2）
    if (isGPTSoVITS(modelType) || modelType == MODEL_TYPE_TACOTRON2){
      modelList.add("open_jtalk");
      modelList.add("open_jtalk_dic_utf_8-1.11/char.bin");

      modelList.add("open_jtalk");
      modelList.add("open_jtalk_dic_utf_8-1.11/COPYING");

      modelList.add("open_jtalk");
      modelList.add("open_jtalk_dic_utf_8-1.11/left-id.def");

      modelList.add("open_jtalk");
      modelList.add("open_jtalk_dic_utf_8-1.11/matrix.bin");

      modelList.add("open_jtalk");
      modelList.add("open_jtalk_dic_utf_8-1.11/pos-id.def");

      modelList.add("open_jtalk");
      modelList.add("open_jtalk_dic_utf_8-1.11/rewrite.def");

      modelList.add("open_jtalk");
      modelList.add("open_jtalk_dic_utf_8-1.11/right-id.def");

      modelList.add("open_jtalk");
      modelList.add("open_jtalk_dic_utf_8-1.11/sys.dic");

      modelList.add("open_jtalk");
      modelList.add("open_jtalk_dic_utf_8-1.11/unk.dic");
    }

    // G2P英語辞書（全GPT-SoVITS）
    if (isGPTSoVITS(modelType)){
      modelList.add("g2p_en");
      modelList.add("averaged_perceptron_tagger_classes.txt");

      modelList.add("g2p_en");
      modelList.add("averaged_perceptron_tagger_tagdict.txt");

      modelList.add("g2p_en");
      modelList.add("averaged_perceptron_tagger_weights.txt");

      modelList.add("g2p_en");
      modelList.add("cmudict");

      modelList.add("g2p_en");
      modelList.add("g2p_decoder.onnx");

      modelList.add("g2p_en");
      modelList.add("g2p_encoder.onnx");

      modelList.add("g2p_en");
      modelList.add("homographs.en");
    }

    // G2P中国語辞書（ZH、またはV3/V2Proは常に必要）
    if (needsCN(modelType)){
      modelList.add("g2p_cn");
      modelList.add("pinyin.txt");

      modelList.add("g2p_cn");
      modelList.add("opencpop-strict.txt");

      modelList.add("g2p_cn");
      modelList.add("jieba.dict.utf8");

      modelList.add("g2p_cn");
      modelList.add("hmm_model.utf8");

      modelList.add("g2p_cn");
      modelList.add("user.dict.utf8");

      modelList.add("g2p_cn");
      modelList.add("idf.utf8");

      modelList.add("g2p_cn");
      modelList.add("stop_words.utf8");
    }

    // G2PW辞書（V3/V2Proは常に、V2はZHのみ）
    if (needsG2PW(modelType)){
      modelList.add("g2pw/1.1");
      modelList.add("g2pW.onnx");

      modelList.add("g2pw/1.1");
      modelList.add("POLYPHONIC_CHARS.txt");

      modelList.add("g2pw/1.1");
      modelList.add("bopomofo_to_pinyin_wo_tune_dict.json");
    }

    // Tacotron2モデル
    if (modelType == MODEL_TYPE_TACOTRON2) {
      modelList.add("tacotron2");
      modelList.add("encoder.onnx");

      modelList.add("tacotron2");
      modelList.add("decoder_iter.onnx");

      modelList.add("tacotron2");
      modelList.add("postnet.onnx");

      modelList.add("tacotron2");
      modelList.add("waveglow.onnx");
    }

    // GPT-SoVITS V1モデル
    if (isV1(modelType)) {
      String folder = getModelFolder(modelType);
      modelList.add(folder);
      modelList.add("t2s_encoder.onnx");

      modelList.add(folder);
      modelList.add("t2s_fsdec.onnx");

      modelList.add(folder);
      modelList.add("t2s_sdec.opt3.onnx");

      modelList.add(folder);
      modelList.add("vits.onnx");

      modelList.add(folder);
      modelList.add("cnhubert.onnx");
    }

    // GPT-SoVITS V2モデル
    if (isV2(modelType)) {
      String folder = getModelFolder(modelType);
      modelList.add(folder);
      modelList.add("t2s_encoder.onnx");

      modelList.add(folder);
      modelList.add("t2s_fsdec.onnx");

      modelList.add(folder);
      modelList.add("t2s_sdec.opt.onnx");

      modelList.add(folder);
      modelList.add("vits.onnx");

      modelList.add(folder);
      modelList.add("cnhubert.onnx");

      modelList.add(folder);
      modelList.add("chinese-roberta.onnx");

      modelList.add(folder);
      modelList.add("vocab.txt");
    }

    // GPT-SoVITS V3モデル
    if (isV3(modelType)) {
      String folder = getModelFolder(modelType);
      modelList.add(folder);
      modelList.add("t2s_encoder.onnx");

      modelList.add(folder);
      modelList.add("t2s_fsdec.onnx");

      modelList.add(folder);
      modelList.add("t2s_sdec.opt.onnx");

      modelList.add(folder);
      modelList.add("cnhubert.onnx");

      modelList.add(folder);
      modelList.add("vq_model.onnx");

      modelList.add(folder);
      modelList.add("vq_cfm.onnx");

      modelList.add(folder);
      modelList.add("bigvgan_model.onnx");

      modelList.add(folder);
      modelList.add("chinese-roberta.onnx");

      modelList.add(folder);
      modelList.add("vocab.txt");
    }

    // GPT-SoVITS V2Proモデル
    if (isV2Pro(modelType)) {
      String folder = getModelFolder(modelType);
      modelList.add(folder);
      modelList.add("t2s_encoder.onnx");

      modelList.add(folder);
      modelList.add("t2s_fsdec.onnx");

      modelList.add(folder);
      modelList.add("t2s_sdec.opt.onnx");

      modelList.add(folder);
      modelList.add("cnhubert.onnx");

      modelList.add(folder);
      modelList.add("vits.onnx");

      modelList.add(folder);
      modelList.add("sv.onnx");

      modelList.add(folder);
      modelList.add("chinese-roberta.onnx");

      modelList.add(folder);
      modelList.add("vocab.txt");
    }

    return modelList;
  }

  Future<void> _downloadFile(String url, String filename) async {
    final completer = Completer<void>();
    downloadModel(url, filename, (file) {
      completer.complete();
    });
    await completer.future;
  }

  // モデルのダウンロード
  Future<void> downloadModels(int modelType, {bool userDictionary = false}) async {
    List<String> list = getModelList(modelType);
    if (userDictionary && (isJA(modelType) || modelType == MODEL_TYPE_TACOTRON2)){
      list.add("open_jtalk");
      list.add("userdic.dic");
    }
    for (int i = 0; i < list.length; i += 2) {
      String url = "https://storage.googleapis.com/ailia-models/${list[i]}/${list[i + 1]}";
      await _downloadFile(url, list[i + 1]);
    }

    // G2PW data files (different URL base)
    if (needsG2PW(modelType)){
      const String g2pwDataUrl = "https://raw.githubusercontent.com/axinc-ai/ailia-models/master/audio_processing/gpt-sovits-v2/text/g2pw/";
      await _downloadFile("${g2pwDataUrl}polyphonic.rep", "polyphonic.rep");
      await _downloadFile("${g2pwDataUrl}polyphonic-fix.rep", "polyphonic-fix.rep");
    }
  }

  // Tacotron2モデルのオープン
  void openTacotron2(
      String encoderFile,
      String decoderFile,
      String postnetFile,
      String waveglowFile,
      String dicFolderOpenJtalk,
      {String? userDictPath}) {
    _ailiaVoiceModel.openModel(
        encoderFile,
        decoderFile,
        postnetFile,
        waveglowFile,
        null,
        ailia_voice_dart.AILIA_VOICE_MODEL_TYPE_TACOTRON2,
        ailia_voice_dart.AILIA_VOICE_CLEANER_TYPE_BASIC,
        ailia_voice_dart.AILIA_ENVIRONMENT_ID_AUTO);
    if (userDictPath != null){
      _ailiaVoiceModel.setUserDictionary(userDictPath, ailia_voice_dart.AILIA_VOICE_DICTIONARY_TYPE_OPEN_JTALK);
    }
    _ailiaVoiceModel.openDictionary(dicFolderOpenJtalk, ailia_voice_dart.AILIA_VOICE_DICTIONARY_TYPE_OPEN_JTALK);
  }

  // GPT-SoVITS V1モデルのオープン
  void openGPTSoVITSV1(
      String encoderFile,
      String decoderFile,
      String sdecFile,
      String vitsFile,
      String sslFile,
      String dicFolderOpenJtalk,
      String dicFolderG2PEn,
      {String? dicFolderG2PCn,
      String? userDictPath}) {
    _ailiaVoiceModel.openGPTSoVITSV1Model(
        encoderFile, decoderFile, sdecFile, vitsFile, sslFile,
        ailia_voice_dart.AILIA_ENVIRONMENT_ID_AUTO);
    if (userDictPath != null){
      _ailiaVoiceModel.setUserDictionary(userDictPath, ailia_voice_dart.AILIA_VOICE_DICTIONARY_TYPE_OPEN_JTALK);
    }
    _ailiaVoiceModel.openDictionary(dicFolderOpenJtalk, ailia_voice_dart.AILIA_VOICE_DICTIONARY_TYPE_OPEN_JTALK);
    _ailiaVoiceModel.openDictionary(dicFolderG2PEn, ailia_voice_dart.AILIA_VOICE_DICTIONARY_TYPE_G2P_EN);
    if (dicFolderG2PCn != null){
      _ailiaVoiceModel.openDictionary(dicFolderG2PCn, ailia_voice_dart.AILIA_VOICE_DICTIONARY_TYPE_G2P_CN);
    }
  }

  // GPT-SoVITS V2モデルのオープン
  void openGPTSoVITSV2(
      String encoderFile,
      String decoderFile,
      String sdecFile,
      String vitsFile,
      String sslFile,
      String chineseBertFile,
      String vocabFile,
      String dicFolderOpenJtalk,
      String dicFolderG2PEn,
      {String? dicFolderG2PCn,
      String? dicFolderG2PW,
      String? userDictPath}) {
    _ailiaVoiceModel.openGPTSoVITSV2Model(
        encoderFile, decoderFile, sdecFile, vitsFile, sslFile,
        chineseBertFile, vocabFile,
        ailia_voice_dart.AILIA_ENVIRONMENT_ID_AUTO);
    if (userDictPath != null){
      _ailiaVoiceModel.setUserDictionary(userDictPath, ailia_voice_dart.AILIA_VOICE_DICTIONARY_TYPE_OPEN_JTALK);
    }
    _ailiaVoiceModel.openDictionary(dicFolderOpenJtalk, ailia_voice_dart.AILIA_VOICE_DICTIONARY_TYPE_OPEN_JTALK);
    _ailiaVoiceModel.openDictionary(dicFolderG2PEn, ailia_voice_dart.AILIA_VOICE_DICTIONARY_TYPE_G2P_EN);
    if (dicFolderG2PCn != null){
      _ailiaVoiceModel.openDictionary(dicFolderG2PCn, ailia_voice_dart.AILIA_VOICE_DICTIONARY_TYPE_G2P_CN);
    }
    if (dicFolderG2PW != null){
      _ailiaVoiceModel.openDictionary(dicFolderG2PW, ailia_voice_dart.AILIA_VOICE_DICTIONARY_TYPE_G2PW);
    }
  }

  // GPT-SoVITS V3モデルのオープン
  void openGPTSoVITSV3(
      String encoderFile,
      String decoderFile,
      String sdecFile,
      String sslFile,
      String vqFile,
      String cfmFile,
      String bigvganFile,
      String chineseBertFile,
      String vocabFile,
      String dicFolderOpenJtalk,
      String dicFolderG2PEn,
      String dicFolderG2PCn,
      String dicFolderG2PW,
      {String? userDictPath}) {
    _ailiaVoiceModel.openGPTSoVITSV3Model(
        encoderFile, decoderFile, sdecFile, sslFile,
        vqFile, cfmFile, bigvganFile,
        chineseBertFile, vocabFile,
        ailia_voice_dart.AILIA_ENVIRONMENT_ID_AUTO);
    if (userDictPath != null){
      _ailiaVoiceModel.setUserDictionary(userDictPath, ailia_voice_dart.AILIA_VOICE_DICTIONARY_TYPE_OPEN_JTALK);
    }
    _ailiaVoiceModel.openDictionary(dicFolderOpenJtalk, ailia_voice_dart.AILIA_VOICE_DICTIONARY_TYPE_OPEN_JTALK);
    _ailiaVoiceModel.openDictionary(dicFolderG2PEn, ailia_voice_dart.AILIA_VOICE_DICTIONARY_TYPE_G2P_EN);
    _ailiaVoiceModel.openDictionary(dicFolderG2PCn, ailia_voice_dart.AILIA_VOICE_DICTIONARY_TYPE_G2P_CN);
    _ailiaVoiceModel.openDictionary(dicFolderG2PW, ailia_voice_dart.AILIA_VOICE_DICTIONARY_TYPE_G2PW);
  }

  // GPT-SoVITS V2Proモデルのオープン
  void openGPTSoVITSV2Pro(
      String encoderFile,
      String decoderFile,
      String sdecFile,
      String sslFile,
      String vitsFile,
      String svFile,
      String chineseBertFile,
      String vocabFile,
      String dicFolderOpenJtalk,
      String dicFolderG2PEn,
      String dicFolderG2PCn,
      String dicFolderG2PW,
      {String? userDictPath}) {
    _ailiaVoiceModel.openGPTSoVITSV2ProModel(
        encoderFile, decoderFile, sdecFile, sslFile,
        vitsFile, svFile,
        chineseBertFile, vocabFile,
        ailia_voice_dart.AILIA_ENVIRONMENT_ID_AUTO);
    if (userDictPath != null){
      _ailiaVoiceModel.setUserDictionary(userDictPath, ailia_voice_dart.AILIA_VOICE_DICTIONARY_TYPE_OPEN_JTALK);
    }
    _ailiaVoiceModel.openDictionary(dicFolderOpenJtalk, ailia_voice_dart.AILIA_VOICE_DICTIONARY_TYPE_OPEN_JTALK);
    _ailiaVoiceModel.openDictionary(dicFolderG2PEn, ailia_voice_dart.AILIA_VOICE_DICTIONARY_TYPE_G2P_EN);
    _ailiaVoiceModel.openDictionary(dicFolderG2PCn, ailia_voice_dart.AILIA_VOICE_DICTIONARY_TYPE_G2P_CN);
    _ailiaVoiceModel.openDictionary(dicFolderG2PW, ailia_voice_dart.AILIA_VOICE_DICTIONARY_TYPE_G2PW);
  }

  // 推論（モデルタイプ共通）
  Future<void> inference(String targetText, String outputPath, int modelType,
      {bool playAudio = true}) async {
    // GPT-SoVITSの場合はリファレンス音声を設定
    if (isGPTSoVITS(modelType)) {
      ByteData data = await rootBundle.load("assets/reference_audio_girl.wav");
      final wav = Wav.read(data.buffer.asUint8List());

      List<double> pcm = List<double>.empty(growable: true);
      for (int i = 0; i < wav.channels[0].length; ++i) {
        for (int j = 0; j < wav.channels.length; ++j) {
          pcm.add(wav.channels[j][i]);
        }
      }

      int g2pType = ailia_voice_dart.AILIA_VOICE_G2P_TYPE_GPT_SOVITS_JA;
      String referenceText = "水をマレーシアから買わなくてはならない。";
      if (isEN(modelType)) {
        g2pType = ailia_voice_dart.AILIA_VOICE_G2P_TYPE_GPT_SOVITS_EN;
        referenceText = "water must be purchased from malaysia.";
      } else if (isZH(modelType)) {
        g2pType = ailia_voice_dart.AILIA_VOICE_G2P_TYPE_GPT_SOVITS_ZH;
        referenceText = "水必须从马来西亚购买。";
      }

      String referenceFeature = _ailiaVoiceModel.g2p(referenceText, g2pType);
      _ailiaVoiceModel.setReference(
          pcm, wav.samplesPerSecond, wav.channels.length, referenceFeature);
    }

    // G2P変換と推論
    String targetFeature = targetText;
    if (isJA(modelType)){
      targetFeature = _ailiaVoiceModel.g2p(targetText,
          ailia_voice_dart.AILIA_VOICE_G2P_TYPE_GPT_SOVITS_JA);
    } else if (isEN(modelType)){
      targetFeature = _ailiaVoiceModel.g2p(targetText,
          ailia_voice_dart.AILIA_VOICE_G2P_TYPE_GPT_SOVITS_EN);
    } else if (isZH(modelType)){
      targetFeature = _ailiaVoiceModel.g2p(targetText,
          ailia_voice_dart.AILIA_VOICE_G2P_TYPE_GPT_SOVITS_ZH);
    }
    final audio = _ailiaVoiceModel.inference(targetFeature);
    if (playAudio) {
      _speaker.play(audio, outputPath);
    }
  }

  // モデルのクローズ
  void close() {
    _ailiaVoiceModel.close();
  }

  // ターゲットテキストの取得
  String _getTargetText(int modelType, {bool userDictionary = false}) {
    if (isJA(modelType)){
      return userDictionary ? "超電磁砲" : "こんにちは世界。";
    } else if (isZH(modelType)){
      return "你好世界。";
    }
    return "Hello world.";
  }

  // モデルパスの準備と推論を一括で実行
  Future<void> run(int modelType, String outputPath, {bool userDictionary = false, bool playAudio = true}) async {
    String targetText = _getTargetText(modelType, userDictionary: userDictionary);
    String dicFolderOpenJtalk = await getModelPath("open_jtalk_dic_utf_8-1.11/");
    String? userDictPath;
    if (userDictionary && (isJA(modelType) || modelType == MODEL_TYPE_TACOTRON2)){
      userDictPath = await getModelPath("userdic.dic");
    }

    if (modelType == MODEL_TYPE_TACOTRON2) {
      openTacotron2(
          await getModelPath("encoder.onnx"),
          await getModelPath("decoder_iter.onnx"),
          await getModelPath("postnet.onnx"),
          await getModelPath("waveglow.onnx"),
          dicFolderOpenJtalk,
          userDictPath: userDictPath);
    } else if (isV1(modelType)) {
      openGPTSoVITSV1(
          await getModelPath("t2s_encoder.onnx"),
          await getModelPath("t2s_fsdec.onnx"),
          await getModelPath("t2s_sdec.opt3.onnx"),
          await getModelPath("vits.onnx"),
          await getModelPath("cnhubert.onnx"),
          dicFolderOpenJtalk,
          await getModelPath("/"),
          dicFolderG2PCn: needsCN(modelType) ? await getModelPath("/") : null,
          userDictPath: userDictPath);
    } else if (isV2(modelType)) {
      openGPTSoVITSV2(
          await getModelPath("t2s_encoder.onnx"),
          await getModelPath("t2s_fsdec.onnx"),
          await getModelPath("t2s_sdec.opt.onnx"),
          await getModelPath("vits.onnx"),
          await getModelPath("cnhubert.onnx"),
          await getModelPath("chinese-roberta.onnx"),
          await getModelPath("vocab.txt"),
          dicFolderOpenJtalk,
          await getModelPath("/"),
          dicFolderG2PCn: needsCN(modelType) ? await getModelPath("/") : null,
          dicFolderG2PW: needsG2PW(modelType) ? await getModelPath("/") : null,
          userDictPath: userDictPath);
    } else if (isV3(modelType)) {
      String basePath = await getModelPath("/");
      openGPTSoVITSV3(
          await getModelPath("t2s_encoder.onnx"),
          await getModelPath("t2s_fsdec.onnx"),
          await getModelPath("t2s_sdec.opt.onnx"),
          await getModelPath("cnhubert.onnx"),
          await getModelPath("vq_model.onnx"),
          await getModelPath("vq_cfm.onnx"),
          await getModelPath("bigvgan_model.onnx"),
          await getModelPath("chinese-roberta.onnx"),
          await getModelPath("vocab.txt"),
          dicFolderOpenJtalk,
          basePath, basePath, basePath,
          userDictPath: userDictPath);
    } else if (isV2Pro(modelType)) {
      String basePath = await getModelPath("/");
      openGPTSoVITSV2Pro(
          await getModelPath("t2s_encoder.onnx"),
          await getModelPath("t2s_fsdec.onnx"),
          await getModelPath("t2s_sdec.opt.onnx"),
          await getModelPath("cnhubert.onnx"),
          await getModelPath("vits.onnx"),
          await getModelPath("sv.onnx"),
          await getModelPath("chinese-roberta.onnx"),
          await getModelPath("vocab.txt"),
          dicFolderOpenJtalk,
          basePath, basePath, basePath,
          userDictPath: userDictPath);
    }

    await inference(targetText, outputPath, modelType, playAudio: playAudio);
    close();
  }
}
