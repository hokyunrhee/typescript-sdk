import { isEventStreamContentType } from '@modelcontextprotocol/core-internal';
import { describe, expect, it } from 'vitest';

describe('isEventStreamContentType', () => {
    it('matches text/event-stream with or without parameters', () => {
        expect(isEventStreamContentType('text/event-stream')).toBe(true);
        expect(isEventStreamContentType('Text/Event-Stream; charset=utf-8')).toBe(true);
    });

    it('rejects other media types and a missing header', () => {
        expect(isEventStreamContentType('application/json')).toBe(false);
        expect(isEventStreamContentType(undefined)).toBe(false);
    });
});
