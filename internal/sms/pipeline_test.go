package sms

import (
	"context"
	"encoding/hex"
	"path/filepath"
	"testing"
	"time"

	"qmi-web/internal/database"
)

func newTestPipeline(t *testing.T) (*Pipeline, *database.Store) {
	t.Helper()
	store, err := database.Open(filepath.Join(t.TempDir(), "qmi-web.db"))
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = store.Close() })
	return &Pipeline{Store: store}, store
}

func TestDecodeKnownDeliverPDU(t *testing.T) {
	raw, err := hex.DecodeString("079144872000302320048102020000625061028204401AD9775D0E72D7DBE2B21C949E8360B75A4E7683D16AB71B")
	if err != nil {
		t.Fatal(err)
	}
	decoded, err := Decode(raw)
	if err != nil {
		t.Fatal(err)
	}
	if decoded.Body == "" || decoded.Sender == "" || decoded.Encoding != "GSM7" {
		t.Fatalf("unexpected decode result: %#v", decoded)
	}
}

func TestDecodeUCS2ChineseAndRejectInvalidPDU(t *testing.T) {
	raw, err := hex.DecodeString("040B912143658709F1000862507241900000044F60597D")
	if err != nil {
		t.Fatal(err)
	}
	decoded, err := Decode(raw)
	if err != nil {
		t.Fatal(err)
	}
	if decoded.Body != "你好" || decoded.Encoding != "UCS2" {
		t.Fatalf("unexpected Chinese UCS2 result: %#v", decoded)
	}
	if _, err := Decode([]byte{0x04, 0x01}); err == nil {
		t.Fatal("invalid PDU was accepted")
	}
}

func TestMultipartReassemblyAndDeduplication(t *testing.T) {
	pipeline, store := newTestPipeline(t)
	now := time.Now().UTC()
	part2 := Decoded{Sender: "+15550000001", Body: "world", Timestamp: now, Encoding: "GSM7", Concat: ConcatInfo{IsConcat: true, Ref: 9, RefBits: 8, Total: 2, Seq: 2}}
	part1 := Decoded{Sender: "+15550000001", Body: "hello ", Timestamp: now, Encoding: "GSM7", Concat: ConcatInfo{IsConcat: true, Ref: 9, RefBits: 8, Total: 2, Seq: 1}}
	if _, saved, err := pipeline.IngestDecoded(context.Background(), "mock", 2, []byte("two"), part2); err != nil || !saved {
		t.Fatalf("first part rejected: saved=%v err=%v", saved, err)
	}
	id, saved, err := pipeline.IngestDecoded(context.Background(), "mock", 1, []byte("one"), part1)
	if err != nil || !saved || id < 1 {
		t.Fatalf("reassembly failed: id=%d saved=%v err=%v", id, saved, err)
	}
	message, err := store.SMS(context.Background(), id)
	if err != nil || message.Body != "hello world" || !message.IsMultipart || message.PartsReceived != 2 || message.Source != "test_fixture" {
		t.Fatalf("unexpected message: %#v %v", message, err)
	}
	if _, saved, err := pipeline.IngestDecoded(context.Background(), "mock", 1, []byte("one"), part1); err != nil || saved {
		t.Fatalf("duplicate was persisted: saved=%v err=%v", saved, err)
	}
}

func TestThreePartOutOfOrderReassembly(t *testing.T) {
	pipeline, store := newTestPipeline(t)
	now := time.Now().UTC()
	for _, item := range []struct {
		index uint32
		seq   int
		body  string
	}{
		{3, 3, "three"},
		{1, 1, "one "},
		{2, 2, "two "},
	} {
		decoded := Decoded{
			Sender: "+15550000002", Body: item.body, Timestamp: now, Encoding: "GSM7",
			Concat: ConcatInfo{IsConcat: true, Ref: 513, RefBits: 16, Total: 3, Seq: item.seq},
		}
		_, _, err := pipeline.IngestDecoded(context.Background(), "mock", item.index, []byte{byte(item.seq)}, decoded)
		if err != nil {
			t.Fatal(err)
		}
	}
	items, total, err := store.ListSMS(context.Background(), 1, 10, "", "")
	if err != nil || total != 1 || items[0].Body != "one two three" {
		t.Fatalf("out-of-order three-part message was not assembled: %#v total=%d err=%v", items, total, err)
	}
}
